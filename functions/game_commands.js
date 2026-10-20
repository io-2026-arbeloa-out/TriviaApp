'use strict';

const { FieldValue } = require('firebase-admin/firestore');

class CommandError extends Error {
  constructor(code, message) { super(message); this.code = code; }
}
const fail = (code, message) => { throw new CommandError(code, message); };
function key(value) {
  if (typeof value !== 'string' || !value || value.length > 256 || /[.#$\[\]/\u0000-\u001f\u007f]/.test(value)) {
    fail('invalid-argument', 'Invalid identifier');
  }
  return value;
}
function settings(data) {
  const value = {
    categoryId: key(data.categoryId), maxPlayers: data.maxPlayers,
    questionTimeLimit: data.questionTimeLimit, difficulty: data.difficulty,
  };
  if (!Number.isInteger(value.maxPlayers) || value.maxPlayers < 2 || value.maxPlayers > 10
    || ![10, 20, 30, 60].includes(value.questionTimeLimit)
    || !['easy', 'medium', 'hard', 'impossible', 'random'].includes(value.difficulty)) {
    fail('invalid-argument', 'Invalid game settings');
  }
  return value;
}
function hostWaiting(session, uid) {
  if (!session) fail('not-found', 'Session not found');
  if (session.hostUid !== uid) fail('permission-denied', 'Only the host may do this');
  if (!session.isPrivate || session.status !== 'waiting') fail('failed-precondition', 'Lobby is not configurable');
}
function counter(count) {
  return { validatedCount: 0, targetCount: count, incorrectUids: [], validatedUids: [], resolved: false };
}
function activeCount(players) {
  return Object.values(players).filter(p => !p.isEliminated).length;
}

function createGameCommands({ db, rtdb, random = Math.random }) {
  const sessionRef = id => db.collection('sessions').doc(key(id));
  async function player(uid) {
    const profile = (await db.collection('users').doc(uid).get()).data();
    if (!profile) fail('failed-precondition', 'Complete your profile first');
    return { username: profile.username, profilePicture: profile.profilePicture || 'defaultAvatar.png',
      isEliminated: false, lotteryTickets: 0, correctAnswers: 0, totalAnswers: 0 };
  }
  async function answerKey(category, id) {
    const snap = await rtdb.ref(`answer_keys/${key(category)}/${key(id)}`).get();
    const correct = snap.val()?.correctAnswers;
    if (!Array.isArray(correct) || !correct.length || !correct.every(a => typeof a === 'string')) {
      fail('failed-precondition', 'Question answer key is missing or invalid');
    }
    return correct;
  }
  async function choose(category, count, difficulty, types, allowShort = false) {
    const snap = await rtdb.ref(`public_questions/${key(category)}`).get();
    const entries = Object.entries(snap.val() || {}).filter(([, q]) => q
      && typeof q.text === 'string' && Array.isArray(q.answers) && q.answers.length >= 2
      && q.answers.every(a => typeof a === 'string')
      && !('correctAnswers' in q) && !('wrongAnswers' in q)
      && (difficulty === 'random' || q.difficulty === difficulty)
      && (!types || types.includes(q.type)));
    for (let i = entries.length - 1; i > 0; i--) {
      const j = Math.floor(random() * (i + 1));
      [entries[i], entries[j]] = [entries[j], entries[i]];
    }
    const selected = entries.slice(0, count);
    if (!selected.length || (!allowShort && selected.length < count)) {
      fail('failed-precondition', 'Not enough questions for these settings');
    }
    await Promise.all(selected.map(([id]) => answerKey(category, id)));
    return selected.map(([id, q]) => ({ id: key(id), text: q.text, answers: q.answers,
      type: q.type, difficulty: q.difficulty }));
  }
  return {
    async createSession(uid, data) {
      const options = settings(data);
      const isPrivate = data.entryCode != null;
      if (isPrivate && (!Number.isInteger(data.entryCode) || data.entryCode < 100000 || data.entryCode > 999999)) {
        fail('invalid-argument', 'Invalid entry code');
      }
      const entry = await player(uid);
      const questions = isPrivate ? [] : await choose(options.categoryId, (options.maxPlayers - 1) * 3, options.difficulty);
      const ref = db.collection('sessions').doc();
      await ref.set({ ...options, hostUid: uid, participantUids: [uid], playerUids: [uid],
        players: { [uid]: entry }, activePlayerCount: 1, status: 'waiting', phase: 'answering',
        isPrivate, entryCode: data.entryCode ?? null, settingsVersion: 0,
        questionIds: questions.map(q => q.id), currentQuestionIndex: 0,
        rounds: [], lastRoundResult: null, createdAt: FieldValue.serverTimestamp(), gameStartTime: null, endTime: null });
      return { sessionId: ref.id };
    },
    async findPrivateSession(uid, data) {
      if (!Number.isInteger(data.entryCode)) fail('invalid-argument', 'Invalid entry code');
      const result = await db.collection('sessions').where('status', '==', 'waiting')
        .where('isPrivate', '==', true).where('entryCode', '==', data.entryCode).limit(1).get();
      return { sessionId: result.empty ? null : result.docs[0].id };
    },
    async joinSession(uid, data) {
      const ref = sessionRef(data.sessionId);
      const entry = await player(uid);
      await db.runTransaction(async tx => {
        const s = (await tx.get(ref)).data();
        if (!s) fail('not-found', 'Session not found');
        if (s.isPrivate && data.entryCode !== s.entryCode) fail('permission-denied', 'Incorrect entry code');
        if (s.status !== 'waiting') fail('failed-precondition', 'Session is no longer waiting');
        if (s.playerUids.includes(uid)) return;
        if (s.playerUids.length >= s.maxPlayers) fail('failed-precondition', 'Session is full');
        const uids = [...s.playerUids, uid];
        const updates = { playerUids: uids, participantUids: FieldValue.arrayUnion(uid),
          [`players.${uid}`]: entry, activePlayerCount: uids.length };
        if (!s.isPrivate && uids.length === s.maxPlayers) {
          if (s.questionIds.length < (s.maxPlayers - 1) * 3) fail('failed-precondition', 'Incomplete question pool');
          updates.status = 'inProgress'; updates.gameStartTime = FieldValue.serverTimestamp();
          tx.set(ref.collection('roundCounters').doc('0'), counter(uids.length));
        }
        tx.update(ref, updates);
      });
      return { sessionId: ref.id };
    },
    async updateSessionSettings(uid, data) {
      const options = settings(data);
      const ref = sessionRef(data.sessionId);
      await db.runTransaction(async tx => {
        const s = (await tx.get(ref)).data(); hostWaiting(s, uid);
        if (s.playerUids.length > options.maxPlayers) fail('failed-precondition', 'Lobby exceeds capacity');
        tx.update(ref, { ...options, settingsVersion: s.settingsVersion + 1, questionIds: [] });
      });
      return {};
    },
    async startSession(uid, data) {
      const ref = sessionRef(data.sessionId);
      const initial = (await ref.get()).data(); hostWaiting(initial, uid);
      const options = settings(initial);
      const questions = await choose(options.categoryId, (options.maxPlayers - 1) * 3, options.difficulty);
      await db.runTransaction(async tx => {
        const s = (await tx.get(ref)).data(); hostWaiting(s, uid);
        if (s.settingsVersion !== initial.settingsVersion) fail('failed-precondition', 'Settings changed; retry starting');
        if (s.playerUids.length < 2 || s.playerUids.length > s.maxPlayers) fail('failed-precondition', 'Invalid player count');
        tx.update(ref, { questionIds: questions.map(q => q.id), status: 'inProgress', gameStartTime: FieldValue.serverTimestamp() });
        tx.set(ref.collection('roundCounters').doc('0'), counter(s.playerUids.length));
      });
      return {};
    },
    async leaveSession(uid, data) {
      const ref = sessionRef(data.sessionId);
      await db.runTransaction(async tx => {
        const s = (await tx.get(ref)).data();
        if (!s) return;
        if (!s.participantUids.includes(uid)) fail('permission-denied', 'Not a participant');
        if (!s.playerUids.includes(uid) || s.status === 'finished') return;
        const remaining = s.playerUids.filter(id => id !== uid);
        if (!remaining.length || (s.status === 'waiting' && s.isPrivate && s.hostUid === uid)) { tx.delete(ref); return; }
        if (s.status === 'waiting') {
          tx.update(ref, { playerUids: remaining, [`players.${uid}`]: FieldValue.delete(), activePlayerCount: remaining.length });
        } else {
          const p = s.players[uid];
          const departed = { ...p, isEliminated: true, voluntaryExit: true,
            eliminationRound: p.eliminationRound ?? s.currentQuestionIndex };
          tx.update(ref, { playerUids: remaining, [`players.${uid}`]: departed,
            activePlayerCount: activeCount({ ...s.players, [uid]: departed }) });
        }
      });
      return {};
    },
    async submitMultiplayerAnswer(uid, data) {
      const ref = sessionRef(data.sessionId);
      const initial = (await ref.get()).data();
      if (!initial?.participantUids.includes(uid)) fail('permission-denied', 'Not a participant');
      const index = data.roundIndex;
      if (!Number.isInteger(index) || index < 0 || typeof data.answer !== 'string' || data.answer.length > 2048) {
        fail('invalid-argument', 'Invalid answer');
      }
      const id = initial.questionIds[index];
      if (id !== data.questionId) fail('invalid-argument', 'Wrong question');
      const correctAnswers = await answerKey(initial.categoryId, id);
      const isCorrect = correctAnswers.includes(data.answer);
      return db.runTransaction(async tx => {
        const answerRef = ref.collection('answers').doc(`${uid}_${index}`);
        const countRef = ref.collection('roundCounters').doc(String(index));
        const [sSnap, aSnap, cSnap] = await Promise.all([tx.get(ref), tx.get(answerRef), tx.get(countRef)]);
        const s = sSnap.data();
        const prior = aSnap.data();
        if (prior) {
          if (prior.answer !== data.answer || prior.questionId !== data.questionId) fail('failed-precondition', 'Answer is already locked');
          return { isCorrect: prior.isCorrect, correctAnswers: prior.correctAnswers };
        }
        if (!s || s.status !== 'inProgress' || s.phase !== 'answering' || s.currentQuestionIndex !== index
          || s.questionIds[index] !== id || s.categoryId !== initial.categoryId || !s.playerUids.includes(uid)
          || s.players[uid]?.isEliminated) fail('failed-precondition', 'Round is not accepting answers');
        const c = cSnap.data();
        if (!c || c.resolved || c.validatedUids.includes(uid)) fail('failed-precondition', 'Round is already resolved');
        tx.create(answerRef, { uid, roundIndex: index, questionId: id, answer: data.answer,
          isCorrect, correctAnswers, answeredAt: FieldValue.serverTimestamp(), validatedAt: FieldValue.serverTimestamp() });
        tx.update(countRef, { validatedCount: c.validatedCount + 1,
          validatedUids: [...c.validatedUids, uid],
          incorrectUids: isCorrect ? c.incorrectUids : [...c.incorrectUids, uid] });
        return { isCorrect, correctAnswers };
      });
    },
    async startSingleplayer(uid, data) {
      if (!Number.isInteger(data.count) || data.count < 1 || data.count > 100
        || !Array.isArray(data.types) || !data.types.length
        || !data.types.every(t => ['true_false', 'open4', 'open6', 'open', 'mixed'].includes(t))) {
        fail('invalid-argument', 'Invalid practice settings');
      }
      const questions = await choose(data.categoryId, data.count, 'random', data.types, true);
      const ref = db.collection('singleplayer_sessions').doc();
      await ref.set({ ownerUid: uid, categoryId: data.categoryId, questionIds: questions.map(q => q.id),
        currentQuestionIndex: 0, createdAt: FieldValue.serverTimestamp() });
      return { sessionId: ref.id, questions };
    },
    async answerSingleplayer(uid, data) {
      const ref = db.collection('singleplayer_sessions').doc(key(data.sessionId));
      const initial = (await ref.get()).data();
      if (!initial || initial.ownerUid !== uid) fail('permission-denied', 'Not your practice session');
      const index = data.roundIndex;
      if (!Number.isInteger(index) || index < 0 || typeof data.answer !== 'string' || data.answer.length > 2048) fail('invalid-argument', 'Invalid answer');
      const id = initial.questionIds[index];
      if (id !== data.questionId) fail('invalid-argument', 'Wrong question');
      const correctAnswers = await answerKey(initial.categoryId, id);
      const isCorrect = data.answer.length > 0 && correctAnswers.some(a => a.trim().toLowerCase() === data.answer.trim().toLowerCase());
      return db.runTransaction(async tx => {
        const answerRef = ref.collection('answers').doc(String(index));
        const [sSnap, aSnap] = await Promise.all([tx.get(ref), tx.get(answerRef)]);
        const s = sSnap.data(); const previous = aSnap.data();
        if (previous) {
          if (previous.answer !== data.answer) fail('failed-precondition', 'Answer is already locked');
          return { isCorrect: previous.isCorrect, correctAnswers: previous.correctAnswers };
        }
        if (!s || s.ownerUid !== uid || s.currentQuestionIndex !== index) fail('failed-precondition', 'Wrong practice round');
        tx.create(answerRef, { answer: data.answer, isCorrect, correctAnswers });
        tx.update(ref, { currentQuestionIndex: index + 1 });
        return { isCorrect, correctAnswers };
      });
    },
  };
}

module.exports = { createGameCommands, CommandError };
