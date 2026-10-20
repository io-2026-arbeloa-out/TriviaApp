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
