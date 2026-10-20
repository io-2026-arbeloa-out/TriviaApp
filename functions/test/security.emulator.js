'use strict';

const { test, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { initializeTestEnvironment, assertSucceeds, assertFails } = require('@firebase/rules-unit-testing');
const { initializeApp, deleteApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { getDatabase } = require('firebase-admin/database');
const { createGameCommands } = require('../game_commands');
const { splitQuestionBank } = require('../scripts/split_questions');
const { createGameLifecycle, DISPLAY_MS } = require('../game_lifecycle');
const fixture = require('../../test/fixtures/public_question_contract.json');
const legacy = require('../../test/fixtures/question_contract.json');

if (!process.env.FIRESTORE_EMULATOR_HOST || !process.env.FIREBASE_DATABASE_EMULATOR_HOST) {
  throw new Error('Run with emulators:exec; production access is forbidden');
}
const projectId = 'demo-triviaapp';
const read = file => fs.readFileSync(path.join(__dirname, '../../', file), 'utf8').replace(/^\uFEFF/, '');
let env, app, db, rtdb, commands;
const profile = name => ({ username: name, profilePicture: 'defaultAvatar.png',
  user_options: { soundVolume: 50, musicVolume: 50, sfxVolume: 50 }, ui_options: 'default',
  totalQuestionsAnswered: 0, correctAnswers: 0, rank: 'unranked', ratingPoints: 0,
  rankedGamesPlayed: 0, rankedGamesWon: 0 });
const options = { categoryId: 'general', maxPlayers: 2, questionTimeLimit: 30, difficulty: 'medium', entryCode: 123456 };
const context = uid => env.authenticatedContext(uid);
const firestore = uid => context(uid).firestore();
const errorCode = code => error => error.code === code;

before(async () => {
  env = await initializeTestEnvironment({ projectId,
    firestore: { rules: read('firestore.rules') }, database: { rules: read('database.rules.json') } });
  app = initializeApp({ projectId, databaseURL: `https://${projectId}.firebaseio.com` }, 'security-tests');
  db = getFirestore(app); rtdb = getDatabase(app);
  commands = createGameCommands({ db, rtdb, random: () => 0.25 });
});
beforeEach(async () => {
  await env.clearFirestore();
  await rtdb.ref().set(fixture);
  await Promise.all(['host', 'guest', 'outsider'].map(uid => db.collection('users').doc(uid).set(profile(uid))));
});
after(async () => { if (env) await env.cleanup(); if (app) await deleteApp(app); });

async function lobby() {
  const { sessionId } = await commands.createSession('host', options);
  await commands.joinSession('guest', { sessionId, entryCode: options.entryCode });
  return sessionId;
}

test('only authenticated users read public questions; keys and legacy data stay private', async () => {
  const database = context('host').database(`https://${projectId}.firebaseio.com`);
  await assertSucceeds(database.ref('public_questions/general').get());
  await assertFails(database.ref('answer_keys/general').get());
  await assertFails(database.ref('questions/general').get());
  await assertFails(database.ref('public_questions/general/01').update({ answers: ['tampered'] }));
  await assertFails(env.unauthenticatedContext().database(`https://${projectId}.firebaseio.com`).ref('public_questions').get());
  const publicData = (await database.ref('public_questions').get()).val();
  assert.equal(JSON.stringify(publicData).includes('correctAnswers'), false);
  assert.equal(JSON.stringify(publicData).includes('wrongAnswers'), false);
});

test('migration strips answer labels and uses the RTDB key', () => {
  assert.deepEqual(splitQuestionBank(legacy), fixture);
  assert.equal(fixture.public_questions.general['01'].id, undefined);
});

test('clients cannot create, edit or delete sessions, counters or answers directly', async () => {
  const id = await lobby();
  const ref = firestore('host').collection('sessions').doc(id);
  await assertFails(ref.update({ status: 'finished' }));
  await assertFails(ref.update({ hostUid: 'outsider' }));
  await assertFails(ref.update({ 'players.guest.correctAnswers': 99 }));
  await assertFails(ref.delete());
  await assertFails(ref.collection('roundCounters').doc('0').set({ resolved: true }));
  await assertFails(ref.collection('answers').doc('host_0').set({ answer: '4' }));
  await assertFails(firestore('host').collection('sessions').doc('fake').set({ hostUid: 'host' }));
  await assertSucceeds(firestore('guest').collection('sessions').doc(id).get());
  await assertFails(firestore('outsider').collection('sessions').doc(id).get());
});

test('server ignores spoofed identity; guests cannot start or change settings', async () => {
  const { sessionId } = await commands.createSession('host', { ...options, uid: 'outsider', questionIds: ['forged'] });
  assert.equal((await db.collection('sessions').doc(sessionId).get()).data().hostUid, 'host');
  await assert.rejects(commands.joinSession('guest', { sessionId, entryCode: 999999 }), errorCode('permission-denied'));
  await commands.joinSession('guest', { sessionId, entryCode: 123456 });
  await assert.rejects(commands.startSession('guest', { sessionId }), errorCode('permission-denied'));
  await assert.rejects(commands.updateSessionSettings('guest', { ...options, sessionId }), errorCode('permission-denied'));
  await commands.updateSessionSettings('host', { ...options, sessionId, questionTimeLimit: 20 });
  await commands.startSession('host', { sessionId });
  const session = (await db.collection('sessions').doc(sessionId).get()).data();
  assert.equal(session.status, 'inProgress'); assert.equal(session.questionTimeLimit, 20);
  assert.equal(session.questionIds.length, 3);
  await assert.rejects(commands.updateSessionSettings('host', { ...options, sessionId }), errorCode('failed-precondition'));
});

test('public queries work but private lobbies are not listable', async () => {
  await commands.createSession('host', options);
  await commands.createSession('host', { ...options, entryCode: null });
  const query = firestore('outsider').collection('sessions').where('status', '==', 'waiting').where('isPrivate', '==', false);
  assert.equal((await assertSucceeds(query.get())).size, 1);
  await assertFails(firestore('outsider').collection('sessions').get());
  const result = await commands.findPrivateSession('guest', { entryCode: options.entryCode });
  assert.equal(typeof result.sessionId, 'string');
});

test('join enforces capacity and auto-starts public games', async () => {
  const { sessionId } = await commands.createSession('host', { ...options, entryCode: null });
  await commands.joinSession('guest', { sessionId });
  const session = (await db.collection('sessions').doc(sessionId).get()).data();
  assert.equal(session.status, 'inProgress'); assert.deepEqual(session.participantUids, ['host', 'guest']);
  await assert.rejects(commands.joinSession('outsider', { sessionId }), errorCode('failed-precondition'));
  assert.equal((await db.collection('sessions').doc(sessionId).collection('roundCounters').doc('0').get()).data().targetCount, 2);
});

test('answers are locked, idempotent and validated using the authoritative question', async () => {
  const sessionId = await lobby(); await commands.startSession('host', { sessionId });
  const ref = db.collection('sessions').doc(sessionId);
  const session = (await ref.get()).data(); const id = session.questionIds[0];
  const answer = fixture.answer_keys.general[id].correctAnswers[0];
  const request = { sessionId, roundIndex: 0, questionId: id, answer };
  await assert.rejects(commands.submitMultiplayerAnswer('outsider', request), errorCode('permission-denied'));
  await assert.rejects(commands.submitMultiplayerAnswer('host', { ...request, questionId: 'forged' }), errorCode('invalid-argument'));
  assert.equal((await commands.submitMultiplayerAnswer('host', request)).isCorrect, true);
  assert.equal((await commands.submitMultiplayerAnswer('host', request)).isCorrect, true);
  await assert.rejects(commands.submitMultiplayerAnswer('host', { ...request, answer: 'other' }), errorCode('failed-precondition'));
  assert.equal((await ref.collection('roundCounters').doc('0').get()).data().validatedCount, 1);
});

test('archive access survives live-session deletion and includes a departed participant', async () => {
  const sessionId = await lobby(); await commands.startSession('host', { sessionId });
  await commands.leaveSession('guest', { sessionId });
  const live = (await db.collection('sessions').doc(sessionId).get()).data();
  assert.equal(live.activePlayerCount, 1); assert.ok(live.participantUids.includes('guest'));
  await db.collection('sessions_archive').doc(sessionId).set({ participantUids: live.participantUids });
  await db.collection('sessions').doc(sessionId).delete();
  await assertSucceeds(firestore('guest').collection('sessions_archive').doc(sessionId).get());
  await assertFails(firestore('outsider').collection('sessions_archive').doc(sessionId).get());
  await assertFails(firestore('guest').collection('sessions_archive').doc(sessionId).update({ participantUids: ['outsider'] }));
});

test('leaving does not edit other players and closes a waiting private host lobby', async () => {
  const sessionId = await lobby();
  await assert.rejects(commands.leaveSession('outsider', { sessionId }), errorCode('permission-denied'));
  await commands.leaveSession('guest', { sessionId, uid: 'host' });
  let session = (await db.collection('sessions').doc(sessionId).get()).data();
  assert.deepEqual(session.playerUids, ['host']); assert.equal(session.players.host.isEliminated, false);
  await commands.leaveSession('host', { sessionId });
  assert.equal((await db.collection('sessions').doc(sessionId).get()).exists, false);
});

test('profile edits cannot create rating or reset server statistics', async () => {
  const owner = firestore('host').collection('users').doc('host');
  await assertSucceeds(owner.update({ username: 'New name' }));
  await assertFails(owner.update({ ratingPoints: 99 }));
  await assertFails(owner.update({ correctAnswers: 99 }));
  await assertFails(firestore('guest').collection('users').doc('host').update({ username: 'Stolen' }));
  await assertFails(firestore('new').collection('users').doc('new').set({ ...profile('New'), ratingPoints: 50 }));
  await assertSucceeds(firestore('new').collection('users').doc('new').set(profile('New')));
});

test('quiz and preset reads are authenticated and never writable by clients', async () => {
  await db.collection('quizzes').doc('general').set({ name: 'General' });
  await db.collection('ui_presets').doc('default').set({ name: 'Default' });
  await assertSucceeds(firestore('host').collection('quizzes').get());
  await assertSucceeds(firestore('host').collection('ui_presets').get());
  await assertFails(firestore('host').collection('ui_presets').doc('default').set({ name: 'Changed' }));
  await assertFails(env.unauthenticatedContext().firestore().collection('quizzes').get());
});

test('singleplayer checks only issued questions and only one answer per round', async () => {
  const start = await commands.startSingleplayer('host', { categoryId: 'general', count: 3, types: ['open4'] });
  assert.equal(JSON.stringify(start.questions).includes('correctAnswers'), false);
  const id = start.questions[0].id; const answer = fixture.answer_keys.general[id].correctAnswers[0];
  const request = { sessionId: start.sessionId, questionId: id, roundIndex: 0, answer };
  await assert.rejects(commands.answerSingleplayer('guest', request), errorCode('permission-denied'));
  await assert.rejects(commands.answerSingleplayer('host', { ...request, questionId: 'forged' }), errorCode('invalid-argument'));
  assert.equal((await commands.answerSingleplayer('host', request)).isCorrect, true);
  assert.equal((await commands.answerSingleplayer('host', request)).isCorrect, true);
  await assert.rejects(commands.answerSingleplayer('host', { ...request, answer: 'different' }), errorCode('failed-precondition'));
  await assertFails(firestore('host').collection('singleplayer_sessions').doc(start.sessionId).update({ currentQuestionIndex: 0 }));
});

test('start rejects a settings race and insufficient question pools without partial writes', async () => {
  const sessionId = await lobby();
  const deferredDb = { ref: questionPath => ({ async get() {
    if (questionPath.startsWith('public_questions/')) {
      await commands.updateSessionSettings('host', { ...options, sessionId, questionTimeLimit: 20 });
    }
    return rtdb.ref(questionPath).get();
  } }) };
  await assert.rejects(createGameCommands({ db, rtdb: deferredDb }).startSession('host', { sessionId }), errorCode('failed-precondition'));
  assert.equal((await db.collection('sessions').doc(sessionId).get()).data().status, 'waiting');
  await commands.updateSessionSettings('host', { ...options, sessionId, maxPlayers: 3 });
  await assert.rejects(commands.startSession('host', { sessionId }), errorCode('failed-precondition'));
});

test('callable wrapper rejects unauthenticated requests', async () => {
  process.env.GCLOUD_PROJECT = projectId;
  process.env.FIREBASE_CONFIG = JSON.stringify({ projectId, databaseURL: `https://${projectId}.firebaseio.com` });
  const handlers = require('../index');
  await assert.rejects(handlers.createSession.run({ data: options }), errorCode('unauthenticated'));
});

async function runningGame({ seconds = 30, publicGame = false, thirdPlayer = false } = {}) {
  let clock = Date.now();
  const scheduled = [];
  const now = () => clock;
  const api = createGameCommands({ db, rtdb, now, random: () => 0.25 });
  if (thirdPlayer) {
    const additions = {};
    for (const [id, question] of Object.entries(fixture.public_questions.general)) {
      additions[`public_questions/general/${id}-copy`] = question;
      additions[`answer_keys/general/${id}-copy`] = fixture.answer_keys.general[id];
    }
    await rtdb.ref().update(additions);
  }
  const enqueue = async (kind, data, due) => scheduled.push({ kind, data, due });
  const engine = createGameLifecycle({ db, now, enqueue, random: () => 0 });
  const { sessionId } = await api.createSession('host', { ...options,
    entryCode: publicGame ? null : options.entryCode, questionTimeLimit: seconds, maxPlayers: thirdPlayer ? 3 : 2 });
  await api.joinSession('guest', { sessionId, entryCode: options.entryCode });
  if (thirdPlayer) await api.joinSession('outsider', { sessionId, entryCode: options.entryCode });
  if (!publicGame) await api.startSession('host', { sessionId });
  const ref = db.collection('sessions').doc(sessionId);
  const read = async () => (await ref.get()).data();
  const answer = async uid => {
    const s = await read(); const questionId = s.questionIds[s.currentQuestionIndex];
    const key = (await rtdb.ref(`answer_keys/general/${questionId}`).get()).val();
    return api.submitMultiplayerAnswer(uid, { sessionId, roundIndex: s.currentQuestionIndex,
      questionId, answer: key.correctAnswers[0] });
  };
  const showResult = async () => { await answer('host'); await answer('guest'); await engine.reconcile(sessionId); };
  const advance = async () => {
    const s = await read(); clock = s.resolveAt.toMillis();
    return engine.advanceRound(sessionId, s.currentQuestionIndex, clock);
  };
  return { api, engine, sessionId, ref, read, answer, showResult, advance, scheduled, enqueue, now,
    setClock: value => { clock = value; } };
}

for (const seconds of [10, 20, 30, 60]) {
  test(`first public round has a ${seconds}s deadline and finishes without any answers`, async () => {
    const game = await runningGame({ seconds, publicGame: true });
    const initial = await game.read();
    assert.equal(initial.roundDeadline.toMillis() - initial.roundStartedAt.toMillis(), seconds * 1000);
    await game.engine.reconcile(game.sessionId);
    const timeout = game.scheduled[0];
    assert.equal(timeout.kind, 'timeout'); assert.equal(timeout.due, initial.roundDeadline.toMillis());
    await assert.rejects(game.engine.resolveRound(game.sessionId, 0, timeout.due), /not elapsed/);
    game.setClock(timeout.due);
    await Promise.all([game.engine.resolveRound(game.sessionId, 0, timeout.due),
      game.engine.resolveRound(game.sessionId, 0, timeout.due)]);
    const resolved = await game.read();
    assert.equal(resolved.rounds.length, 1);
    assert.deepEqual(resolved.rounds[0].isCorrect, { host: false, guest: false });
    await game.advance();
    assert.equal((await game.read()).resultsReady, true);
    assert.equal((await db.collection('sessions_archive').doc(game.sessionId).get()).data().rounds.length, 1);
  });
}

test('every round persists its answers; duplicate/stale tasks never reset the next counter', async () => {
  const game = await runningGame();
  await game.ref.update({ mode: 'ranked' });
  const firstDeadline = (await game.read()).roundDeadline.toMillis();
  for (let i = 0; i < 3; i++) {
    await game.showResult();
    const s = await game.read();
    await assert.rejects(game.engine.advanceRound(game.sessionId, i, s.resolveAt.toMillis()), /not elapsed/);
    await game.advance();
    await game.engine.advanceRound(game.sessionId, i, s.resolveAt.toMillis());
    if (i === 0) {
      await game.answer('host');
      await game.engine.resolveRound(game.sessionId, 0, firstDeadline);
      assert.equal((await game.ref.collection('roundCounters').doc('1').get()).data().validatedCount, 1);
      const fresh = await game.read();
      assert.equal(fresh.roundDeadline.toMillis() - fresh.roundStartedAt.toMillis(), 30000);
    }
  }
  const archive = (await db.collection('sessions_archive').doc(game.sessionId).get()).data();
  assert.equal(archive.rounds.length, 3);
  for (const round of archive.rounds) {
    assert.deepEqual(round.isCorrect, { host: true, guest: true });
    assert.ok(round.playerAnswers.host); assert.ok(round.playerAnswers.guest);
  }
  const before = (await db.collection('users').doc('host').get()).data();
  assert.equal(before.correctAnswers, 3); assert.equal(before.totalQuestionsAnswered, 3);
  assert.equal(before.rankedGamesPlayed, 1);
  assert.equal((await db.collection('users').doc('guest').get()).data().rankedGamesWon, 1);
  await game.engine.reconcile(game.sessionId); await game.engine.cleanup(game.sessionId);
  await game.engine.cleanup(game.sessionId); await game.engine.reconcile(game.sessionId);
  assert.deepEqual((await db.collection('users').doc('host').get()).data(), before);
  assert.equal((await game.ref.collection('answers').get()).empty, true);
  await assertSucceeds(firestore('guest').collection('sessions').doc(game.sessionId).get());
  await assertSucceeds(firestore('guest').collection('sessions_archive').doc(game.sessionId).get());
  await assertFails(firestore('outsider').collection('sessions').doc(game.sessionId).get());
});

test('timeout racing a late answer locks one result and cannot resurrect the round', async () => {
  const game = await runningGame();
  const initial = await game.read(); game.setClock(initial.roundDeadline.toMillis());
  const [answer, timeout] = await Promise.allSettled([game.answer('guest'),
    game.engine.resolveRound(game.sessionId, 0, initial.roundDeadline.toMillis())]);
  assert.equal(answer.status, 'rejected'); assert.equal(answer.reason.code, 'failed-precondition');
  assert.equal(timeout.status, 'fulfilled');
  assert.equal((await game.read()).rounds.length, 1);
  assert.equal((await game.read()).players.guest.correctAnswers, 0);
});

test('leave racing resolution uses fresh players and preserves an already accepted answer', async () => {
  const game = await runningGame(); await game.answer('guest');
  const deadline = (await game.read()).roundDeadline.toMillis(); game.setClock(deadline);
  await Promise.all([game.api.leaveSession('guest', { sessionId: game.sessionId }),
    game.engine.resolveRound(game.sessionId, 0, deadline)]);
  await game.engine.reconcile(game.sessionId);
  const session = await game.read();
  assert.equal(session.players.guest.isEliminated, true);
  assert.equal(session.players.guest.voluntaryExit, true);
  assert.equal(session.activePlayerCount, Object.values(session.players).filter(p => !p.isEliminated).length);
  assert.equal(session.rounds[0].playerAnswers.guest.length > 0, true);
  assert.equal(session.players.guest.correctAnswers, 1);
});

test('leaving while resolving and the last player leaving still produce a complete archive', async () => {
  const game = await runningGame(); await game.showResult();
  await game.api.leaveSession('host', { sessionId: game.sessionId });
  await game.api.leaveSession('guest', { sessionId: game.sessionId });
  assert.equal((await game.read()).phase, 'resolving');
  await game.advance();
  const archive = (await db.collection('sessions_archive').doc(game.sessionId).get()).data();
  assert.deepEqual(archive.participantUids, ['host', 'guest']);
  assert.equal(archive.rounds.length, 1); assert.equal(archive.rounds[0].isCorrect.host, true);
});

test('the last player leaving during answering is resolved and archived rather than deleted', async () => {
  const game = await runningGame();
  await game.api.leaveSession('host', { sessionId: game.sessionId });
  await game.api.leaveSession('guest', { sessionId: game.sessionId });
  await game.engine.reconcile(game.sessionId);
  assert.equal((await game.read()).activePlayerCount, 0);
  await game.advance();
  assert.equal((await game.read()).resultsReady, true);
});

// Inject an interruption at any write inside a transaction, or after its commit.
function interruptedDb({ writeNumber, afterCommit = false } = {}) {
  let armed = true;
  return {
    collection: db.collection.bind(db), batch: db.batch.bind(db),
    async runTransaction(callback) {
      const result = await db.runTransaction(async tx => {
        let writes = 0;
        return callback(new Proxy(tx, { get(target, name) {
          return (...args) => {
            const result = target[name](...args);
            if (armed && ['create', 'set', 'update', 'delete'].includes(name) && ++writes === writeNumber) {
              armed = false; throw new Error('Injected write interruption');
            }
            return result;
          };
        } }));
      });
      if (armed && afterCommit) { armed = false; throw new Error('Injected post-commit interruption'); }
      return result;
    },
  };
}

for (const writeNumber of [1, 2, 3, 4]) {
  test(`finalization interrupted at write ${writeNumber} commits no partial archive or statistics`, async () => {
    const game = await runningGame();
    await game.api.leaveSession('guest', { sessionId: game.sessionId });
    await game.engine.reconcile(game.sessionId);
    const s = await game.read(); game.setClock(s.resolveAt.toMillis());
    const interrupted = createGameLifecycle({ db: interruptedDb({ writeNumber }), now: game.now, enqueue: game.enqueue });
    await assert.rejects(interrupted.advanceRound(game.sessionId, 0, s.resolveAt.toMillis()), /Injected/);
    assert.equal((await game.read()).resultsReady, false);
    assert.equal((await db.collection('sessions_archive').doc(game.sessionId).get()).exists, false);
    assert.equal((await db.collection('users').doc('host').get()).data().totalQuestionsAnswered, 0);
    await game.advance(); await game.advance();
    assert.equal((await db.collection('users').doc('host').get()).data().totalQuestionsAnswered, 1);
  });
}

test('retry after a committed finalization neither changes the archive nor increments stats twice', async () => {
  const game = await runningGame(); await game.api.leaveSession('guest', { sessionId: game.sessionId });
  await game.engine.reconcile(game.sessionId);
  const s = await game.read(); game.setClock(s.resolveAt.toMillis());
  const interrupted = createGameLifecycle({ db: interruptedDb({ afterCommit: true }), now: game.now, enqueue: game.enqueue });
  await assert.rejects(interrupted.advanceRound(game.sessionId, 0, s.resolveAt.toMillis()), /post-commit/);
  const archive = (await db.collection('sessions_archive').doc(game.sessionId).get()).data();
  await game.engine.advanceRound(game.sessionId, 0, s.resolveAt.toMillis());
  await game.engine.reconcile(game.sessionId);
  assert.deepEqual((await db.collection('sessions_archive').doc(game.sessionId).get()).data(), archive);
  assert.equal((await db.collection('users').doc('host').get()).data().totalQuestionsAnswered, 1);
});

test('enqueue interruption after resolution is recoverable from persisted state', async () => {
  const game = await runningGame(); await game.answer('host'); await game.answer('guest');
  const interrupted = createGameLifecycle({ db, now: game.now, enqueue: async () => { throw new Error('Queue unavailable'); } });
  await assert.rejects(interrupted.reconcile(game.sessionId), /Queue unavailable/);
  assert.equal((await game.read()).phase, 'resolving');
  await game.engine.reconcile(game.sessionId);
  assert.equal(game.scheduled.at(-1).kind, 'advance');
  await game.advance();
  await game.engine.reconcile(game.sessionId);
  assert.equal(game.scheduled.at(-1).kind, 'timeout');
  assert.equal((await game.read()).rounds.length, 1);
});

test('cleanup interrupted between batches is resumable and never removes the archive', async () => {
  const game = await runningGame(); await game.api.leaveSession('guest', { sessionId: game.sessionId });
  await game.engine.reconcile(game.sessionId); await game.advance();
  const batch = db.batch();
  for (let i = 0; i < 205; i++) batch.set(game.ref.collection('answers').doc(`extra${i}`), { roundIndex: 0 });
  await batch.commit();
  let batches = 0;
  const flaky = { collection: db.collection.bind(db), batch: () => {
    const batch = db.batch();
    const commit = batch.commit.bind(batch);
    batch.commit = async () => { if (++batches === 2) throw new Error('Cleanup interrupted'); return commit(); };
    return batch;
  } };
  await assert.rejects(createGameLifecycle({ db: flaky }).cleanup(game.sessionId), /Cleanup interrupted/);
  assert.equal((await game.ref.get()).exists, true);
  assert.equal((await game.ref.collection('answers').get()).size, 5);
  await game.engine.cleanup(game.sessionId); await game.engine.cleanup(game.sessionId);
  assert.equal((await game.ref.get()).exists, false);
  assert.equal((await db.collection('sessions_archive').doc(game.sessionId).get()).data().statsApplied, true);
  assert.equal((await db.collection('users').doc('host').get()).data().totalQuestionsAnswered, 1);
});

test('an answered player leaving cannot substitute for an active player who has not answered', async () => {
  const game = await runningGame({ thirdPlayer: true });
  await game.answer('host'); await game.answer('guest');
  await game.api.leaveSession('guest', { sessionId: game.sessionId });
  await game.engine.reconcile(game.sessionId);
  assert.equal((await game.read()).phase, 'answering');
  await game.answer('outsider'); await game.engine.reconcile(game.sessionId);
  const s = await game.read();
  assert.equal(s.phase, 'resolving');
  assert.equal(s.players.guest.correctAnswers, 1);
  assert.deepEqual(s.rounds[0].isCorrect, { host: true, guest: true, outsider: true });
});

test('a committed resolution survives interruption before its follow-up task is scheduled', async () => {
  const game = await runningGame(); await game.answer('host'); await game.answer('guest');
  const interrupted = createGameLifecycle({ db: interruptedDb({ afterCommit: true }), now: game.now, enqueue: game.enqueue });
  await assert.rejects(interrupted.resolveRound(game.sessionId, 0), /post-commit/);
  await game.engine.reconcile(game.sessionId);
  assert.equal(game.scheduled.at(-1).kind, 'advance');
  assert.equal((await game.read()).players.host.correctAnswers, 1);
  assert.equal((await game.read()).rounds.length, 1);
});

test('a committed advancement survives interruption without overwriting a new round answer', async () => {
  const game = await runningGame(); await game.showResult();
  const s = await game.read(); game.setClock(s.resolveAt.toMillis());
  const interrupted = createGameLifecycle({ db: interruptedDb({ afterCommit: true }), now: game.now, enqueue: game.enqueue });
  await assert.rejects(interrupted.advanceRound(game.sessionId, 0, s.resolveAt.toMillis()), /post-commit/);
  await game.answer('host');
  await game.engine.advanceRound(game.sessionId, 0, s.resolveAt.toMillis());
  await game.engine.reconcile(game.sessionId);
  assert.equal(game.scheduled.at(-1).kind, 'timeout');
  assert.equal((await game.ref.collection('roundCounters').doc('1').get()).data().validatedCount, 1);
});

test('finished without result readiness is repaired, using settlement proof to avoid a second increment', async () => {
  const game = await runningGame(); await game.api.leaveSession('guest', { sessionId: game.sessionId });
  await game.engine.reconcile(game.sessionId); await game.advance();
  const archive = (await db.collection('sessions_archive').doc(game.sessionId).get()).data();
  await game.ref.update({ resultsReady: false });
  await game.engine.reconcile(game.sessionId);
  assert.equal((await game.read()).resultsReady, true);
  assert.equal((await db.collection('users').doc('host').get()).data().totalQuestionsAnswered, 1);
  assert.deepEqual((await db.collection('sessions_archive').doc(game.sessionId).get()).data(), archive);
});

// Contract coverage now exercises the callable command, replacing the obsolete
// validator used by the removed onAnswerCreate trigger.
for (const id of Object.keys(fixture.answer_keys.general)) {
  test(`the server validates the exact string question key ${id}`, async () => {
    const game = await runningGame();
    await game.ref.update({ questionIds: [id] });
    const request = { sessionId: game.sessionId, roundIndex: 0, questionId: id,
      answer: fixture.answer_keys.general[id].correctAnswers[0] };
    await assert.rejects(game.api.submitMultiplayerAnswer('host', { ...request, questionId: 'different' }), errorCode('invalid-argument'));
    assert.equal((await game.ref.collection('roundCounters').doc('0').get()).data().validatedCount, 0);
    assert.equal((await game.api.submitMultiplayerAnswer('host', request)).isCorrect, true);
    assert.equal((await game.api.submitMultiplayerAnswer('guest', { ...request, answer: 'incorrect' })).isCorrect, false);
  });
}

test('invalid round, null answer and unsafe question keys cannot create an answer', async () => {
  const game = await runningGame(); const s = await game.read();
  const request = { sessionId: game.sessionId, roundIndex: 0, questionId: s.questionIds[0], answer: 'A' };
  await assert.rejects(game.api.submitMultiplayerAnswer('host', { ...request, roundIndex: 1 }), errorCode('invalid-argument'));
  await assert.rejects(game.api.submitMultiplayerAnswer('host', { ...request, answer: null }), errorCode('invalid-argument'));
  await game.ref.update({ questionIds: ['../other'] });
  await assert.rejects(game.api.submitMultiplayerAnswer('host', { ...request, questionId: '../other' }), errorCode('invalid-argument'));
  assert.equal((await game.ref.collection('answers').get()).empty, true);
});

for (const correctAnswers of [null, 'not-an-array']) {
  test(`missing or malformed answer key (${correctAnswers}) fails without counting an answer`, async () => {
    const game = await runningGame(); const id = (await game.read()).questionIds[0];
    await rtdb.ref(`answer_keys/general/${id}`).set(correctAnswers == null ? null : { correctAnswers });
    await assert.rejects(game.api.submitMultiplayerAnswer('host', {
      sessionId: game.sessionId, roundIndex: 0, questionId: id, answer: 'A',
    }), errorCode('failed-precondition'));
    assert.equal((await game.ref.collection('roundCounters').doc('0').get()).data().validatedCount, 0);
    assert.equal((await game.ref.collection('answers').get()).empty, true);
  });
}
