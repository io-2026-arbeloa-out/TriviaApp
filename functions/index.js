'use strict';

const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { setGlobalOptions }                      = require('firebase-functions/v2');
const admin                                     = require('firebase-admin');

setGlobalOptions({ region: 'europe-central2' });

admin.initializeApp();

const db  = admin.firestore();
const rtdb = admin.database();
const FV  = admin.firestore.FieldValue;

const RESOLVE_DISPLAY_MS = 5_000;

const skip = new Error('SKIP');

// ─────────────────────────────────────────────────────────────────────────────
function weightedRandom(pool) {
  const weights = pool.map(p => (p.lotteryTickets || 0) + 1);
  const total   = weights.reduce((a, b) => a + b, 0);
  let   r       = Math.random() * total;
  for (let i = 0; i < pool.length; i++) {
    r -= weights[i];
    if (r <= 0) return pool[i].uid;
  }
  return pool[pool.length - 1].uid;
}

function countActivePlayers(playersMap) {
  return Object.values(playersMap || {}).filter(p => !p.isEliminated).length;
}

/** Flatten incorrectUids — handles legacy nested-array entries from arrayUnion([uid]). */
function normalizeIncorrectUids(raw) {
  const out = [];
  for (const item of raw || []) {
    if (typeof item === 'string') {
      out.push(item);
    } else if (Array.isArray(item)) {
      for (const inner of item) {
        if (typeof inner === 'string') out.push(inner);
      }
    }
  }
  return [...new Set(out)];
}

async function validateAnswerViaRtdb(categoryId, questionId, answer) {
  const index = parseInt(questionId, 10);
  if (!categoryId || Number.isNaN(index)) return false;

  const snap = await rtdb.ref(`${categoryId}/questions/${index}`).get();
  if (!snap.exists()) return false;

  const question = snap.val();
  const correct = question?.correctAnswers || [];
  return correct.includes(answer);
}

async function deleteAnswersForRound(sessionRef, roundIndex) {
  const snap = await sessionRef
    .collection('answers')
    .where('roundIndex', '==', roundIndex)
    .get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
}

async function deleteSubcollectionDocs(colRef) {
  const snap = await colRef.get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
}

// ─────────────────────────────────────────────────────────────────────────────
// tryResolveFromCounter — shared entry when counter may have reached target
// ─────────────────────────────────────────────────────────────────────────────
async function tryResolveFromCounter(sessionId, roundIndex, counterData, session, sessionRef) {
  if (!counterData || counterData.resolved === true) return;

  if (session.status !== 'inProgress') return;
  if (session.phase !== 'answering') return;
  if (session.currentQuestionIndex !== roundIndex) return;

  const target = counterData.targetCount || session.activePlayerCount || 0;
  if (target <= 0) return;
  if ((counterData.validatedCount || 0) < target) return;

  await resolveRound(
    sessionId,
    roundIndex,
    normalizeIncorrectUids(counterData.incorrectUids),
    session,
    sessionRef,
    counterData,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. onAnswerCreate
// ─────────────────────────────────────────────────────────────────────────────
exports.onAnswerCreate = onDocumentCreated(
  'sessions/{sessionId}/answers/{answerId}',
  async (event) => {
    const { sessionId } = event.params;
    const answerRef = event.data.ref;
    const answerData = event.data.data();
    if (!answerData) return;

    const { uid, roundIndex, questionId, answer } = answerData;
    if (uid == null || roundIndex == null || questionId == null || answer == null) return;
    if (answerData.validatedAt != null) return;

    const sessionRef  = db.collection('sessions').doc(sessionId);
    const sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) return;

    const session = sessionSnap.data();
    if (session.status !== 'inProgress') return;
    if (session.phase !== 'answering') return;
    if (session.currentQuestionIndex !== roundIndex) return;

    const player = session.players?.[uid];
    if (!player || player.isEliminated) return;

    const isCorrect = await validateAnswerViaRtdb(
      session.categoryId,
      String(questionId),
      answer,
    );

    const counterRef = sessionRef.collection('roundCounters').doc(String(roundIndex));
    const counterUpdate = { validatedCount: FV.increment(1) };
    if (!isCorrect) {
      counterUpdate.incorrectUids = FV.arrayUnion(uid);
    }

    const batch = db.batch();
    batch.update(answerRef, {
      isCorrect,
      validatedAt: FV.serverTimestamp(),
    });
    batch.set(counterRef, counterUpdate, { merge: true });
    await batch.commit();
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// 2. onCounterUpdate
// ─────────────────────────────────────────────────────────────────────────────
exports.onCounterUpdate = onDocumentWritten(
  'sessions/{sessionId}/roundCounters/{roundIndex}',
  async (event) => {
    const after = event.data.after.data();
    if (!after) return;

    const { sessionId, roundIndex } = event.params;
    const rIdx = parseInt(roundIndex, 10);

    const sessionRef  = db.collection('sessions').doc(sessionId);
    const sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) return;

    await tryResolveFromCounter(
      sessionId,
      rIdx,
      after,
      sessionSnap.data(),
      sessionRef,
    );
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// resolveRound
// ─────────────────────────────────────────────────────────────────────────────
async function resolveRound(
  sessionId,
  roundIndex,
  incorrectUids,
  session,
  sessionRef,
  counterData,
) {
  const counterRef = sessionRef.collection('roundCounters').doc(String(roundIndex));

  if (counterData?.resolved === true) return;

  const playersMap  = session.players || {};
  const activeUids  = Object.keys(playersMap).filter(uid => !playersMap[uid].isEliminated);

  let eliminatedUid   = null;
  let lotteryOccurred = false;
  let lotteryPool     = [];

  const incorrectActive = incorrectUids.filter(uid => activeUids.includes(uid));

  if (incorrectActive.length === 1) {
    eliminatedUid = incorrectActive[0];
  } else if (incorrectActive.length > 1) {
    lotteryOccurred = true;
    lotteryPool     = incorrectActive;
    eliminatedUid   = weightedRandom(
      lotteryPool.map(uid => ({
        uid,
        lotteryTickets: playersMap[uid]?.lotteryTickets || 0,
      })),
    );
  }

  const eliminatedUsername = eliminatedUid
    ? (playersMap[eliminatedUid]?.username || '')
    : null;

  const updates = {
    phase: 'resolving',
    lastRoundResult: {
      eliminatedUid,
      eliminatedUsername,
      lotteryOccurred,
      lotteryPool,
    },
    rounds: FV.arrayUnion([{
      roundIndex,
      questionId: (session.questionIds || [])[roundIndex] || '',
      eliminatedUid,
      lotteryOccurred,
      lotteryPool,
    }]),
  };

  if (eliminatedUid) {
    updates[`players.${eliminatedUid}.isEliminated`]     = true;
    updates[`players.${eliminatedUid}.eliminationRound`] = roundIndex;
    updates['activePlayerCount']                          = FV.increment(-1);
  }

  if (lotteryOccurred && eliminatedUid) {
    for (const uid of lotteryPool) {
      if (uid !== eliminatedUid) {
        updates[`players.${uid}.lotteryTickets`] = FV.increment(1);
      }
    }
  }

  for (const uid of activeUids) {
    updates[`players.${uid}.totalAnswers`] = FV.increment(1);
    if (!incorrectActive.includes(uid)) {
      updates[`players.${uid}.correctAnswers`] = FV.increment(1);
    }
  }

  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(sessionRef);
      const data = snap.data();
      if (!data || data.phase !== 'answering') throw skip;
      if (data.currentQuestionIndex !== roundIndex) throw skip;

      const counterSnap = await tx.get(counterRef);
      const counter = counterSnap.data();
      if (counter?.resolved === true) throw skip;

      tx.update(sessionRef, updates);
      tx.update(counterRef, { resolved: true });
    });
  } catch (e) {
    if (e === skip) return;
    throw e;
  }

  const roundAnswersSnap = await sessionRef
    .collection('answers')
    .where('roundIndex', '==', roundIndex)
    .get();

  const answerDetails = {};
  const isCorrectMap  = {};
  roundAnswersSnap.forEach(doc => {
    const d = doc.data();
    if (d.uid) {
      answerDetails[d.uid] = d.answer || '';
      isCorrectMap[d.uid]  = d.isCorrect === true;
    }
  });

  await deleteAnswersForRound(sessionRef, roundIndex);

  await new Promise(r => setTimeout(r, RESOLVE_DISPLAY_MS));

  const freshSnap      = await sessionRef.get();
  const fresh          = freshSnap.data();
  if (!fresh || fresh.status !== 'inProgress') return;

  const newActiveCount = fresh.activePlayerCount || 0;
  const nextIndex      = roundIndex + 1;
  const totalQuestions = (fresh.questionIds || []).length;

  if (newActiveCount <= 1 || nextIndex >= totalQuestions) {
    await finishGame(sessionRef, fresh, { roundIndex, answerDetails, isCorrectMap });
  } else {
    await sessionRef
      .collection('roundCounters')
      .doc(String(nextIndex))
      .set({
        validatedCount: 0,
        targetCount:    newActiveCount,
        incorrectUids:  [],
        resolved:       false,
      }, { merge: true });

    await sessionRef.update({
      phase:                'answering',
      currentQuestionIndex: nextIndex,
      lastRoundResult:      null,
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// finishGame + buildArchive
// ─────────────────────────────────────────────────────────────────────────────
async function finishGame(sessionRef, sessionData, lastRoundEnrichment) {
  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(sessionRef);
      if (snap.data()?.status === 'finished') throw skip;
      tx.update(sessionRef, {
        status:  'finished',
        phase:   'finished',
        endTime: FV.serverTimestamp(),
      });
    });
  } catch (e) {
    if (e === skip) return;
    throw e;
  }

  await buildArchive(sessionRef.id, sessionData, lastRoundEnrichment);
}

async function buildArchive(sessionId, session, lastRoundEnrichment) {
  const playersMap = session.players || {};

  const sorted = Object.entries(playersMap).sort(([, a], [, b]) => {
    if (a.eliminationRound == null && b.eliminationRound == null) return 0;
    if (a.eliminationRound == null) return -1;
    if (b.eliminationRound == null) return  1;
    return b.eliminationRound - a.eliminationRound;
  });

  const playerResults = sorted.map(([uid, p], i) => ({
    uid,
    username:         p.username        || '',
    placement:        i + 1,
    correctAnswers:   p.correctAnswers  || 0,
    totalAnswers:     p.totalAnswers    || 0,
    eliminationRound: p.eliminationRound ?? null,
    lotteryTimesIn:   p.lotteryTickets  || 0,
  }));

  const rounds = (session.rounds || []).map(r => {
    const base = {
      roundIndex:      r.roundIndex,
      questionId:      r.questionId,
      playerAnswers:   {},
      isCorrect:       {},
      lotteryOccurred: r.lotteryOccurred || false,
      lotteryPool:     r.lotteryPool     || [],
      eliminatedUid:   r.eliminatedUid   ?? null,
    };
    if (
      lastRoundEnrichment &&
      r.roundIndex === lastRoundEnrichment.roundIndex
    ) {
      base.playerAnswers = lastRoundEnrichment.answerDetails || {};
      base.isCorrect     = lastRoundEnrichment.isCorrectMap  || {};
    }
    return base;
  });

  const now = new Date().toISOString();

  await db.collection('sessions_archive').doc(sessionId).set({
    sessionId,
    categoryId:       session.categoryId  || '',
    gameMode:         session.mode        || 'casual',
    sessionStartTime: session.createdAt?.toDate?.()?.toISOString()     || now,
    gameStartTime:    session.gameStartTime?.toDate?.()?.toISOString() || now,
    endTime:          now,
    playerResults,
    rounds,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// syncRoundTargetAfterPlayerLeave — called from onSessionWrite
// ─────────────────────────────────────────────────────────────────────────────
async function syncRoundTargetAfterPlayerLeave(sessionRef, session) {
  if (session.status !== 'inProgress' || session.phase !== 'answering') return;

  const roundIndex = session.currentQuestionIndex ?? 0;
  const activeCount = countActivePlayers(session.players);

  const counterRef = sessionRef.collection('roundCounters').doc(String(roundIndex));
  const counterSnap = await counterRef.get();
  if (!counterSnap.exists) return;

  const counter = counterSnap.data();
  if (counter.resolved === true) return;

  await counterRef.set({ targetCount: activeCount }, { merge: true });

  const updatedSnap = await counterRef.get();
  await tryResolveFromCounter(
    sessionRef.id,
    roundIndex,
    updatedSnap.data(),
    session,
    sessionRef,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. onSessionWrite — cleanup + leave sync
// ─────────────────────────────────────────────────────────────────────────────
exports.onSessionWrite = onDocumentWritten(
  'sessions/{sessionId}',
  async (event) => {
    const before = event.data.before?.data();
    const after  = event.data.after;
    const docRef = after.ref;

    if (!after.exists) {
      await deleteSubcollectionDocs(docRef.collection('answers'));
      await deleteSubcollectionDocs(docRef.collection('roundCounters'));
      return;
    }

    const data = after.data();

    if (
      before &&
      data.status === 'inProgress' &&
      data.phase === 'answering' &&
      (data.activePlayerCount ?? 0) < (before.activePlayerCount ?? 0)
    ) {
      await syncRoundTargetAfterPlayerLeave(docRef, data);
    }

    if ((data.playerUids || []).length > 0) return;

    if (data.status === 'waiting' || data.status === 'inProgress') {
      await deleteSubcollectionDocs(docRef.collection('answers'));
      await deleteSubcollectionDocs(docRef.collection('roundCounters'));
      await docRef.delete();
    }
  },
);
