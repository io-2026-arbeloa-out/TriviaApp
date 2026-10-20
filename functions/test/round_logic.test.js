'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const { Timestamp } = require('firebase-admin/firestore');
const { calculateRound, buildArchive } = require('../round_logic');
const { createTaskScheduler } = require('../task_scheduler');

const player = username => ({ username, profilePicture: 'avatar.png', isEliminated: false,
  lotteryTickets: 0, totalAnswers: 0, correctAnswers: 0 });
const session = () => ({ players: { a: player('A'), b: player('B') }, rounds: [],
  currentQuestionIndex: 0, questionIds: ['01', '1', 'alpha'], participantUids: ['a', 'b'], categoryId: 'general' });
const correct = { a: { answer: 'A', isCorrect: true }, b: { answer: 'B', isCorrect: true } };

test('a round without errors preserves players until the third consecutive round', () => {
  const input = session();
  assert.equal(calculateRound(input, correct, ['a', 'b'], () => 0).round.eliminatedUid, null);
  input.rounds = [{ eliminatedUid: null }, { eliminatedUid: null }];
  const result = calculateRound(input, correct, ['a', 'b'], () => 0);
  assert.equal(result.round.eliminatedUid, 'a');
  assert.equal(result.players.b.lotteryTickets, 1);
  assert.equal(input.players.b.lotteryTickets, 0);
  assert.deepEqual(result.round.playerAnswers, { a: 'A', b: 'B' });
});

test('one incorrect player is eliminated without a lottery', () => {
  const result = calculateRound(session(), { a: correct.a }, ['a', 'b'], () => 0);
  assert.equal(result.round.eliminatedUid, 'b');
  assert.equal(result.round.lotteryOccurred, false);
  assert.deepEqual(result.round.isCorrect, { a: true, b: false });
  assert.equal(result.players.b.totalAnswers, 1);
  assert.equal(result.players.b.correctAnswers, 0);
});

test('missing answers are incorrect and weighted randomness is injectable', () => {
  const input = session(); input.players.b.lotteryTickets = 4;
  const result = calculateRound(input, {}, ['a', 'b'], () => 0.5);
  assert.equal(result.round.eliminatedUid, 'b');
  assert.deepEqual(result.round.lotteryPool, { a: 0, b: 4 });
  assert.deepEqual(result.round.playerAnswers, { a: '', b: '' });
});

test('a departure preserves accepted answers without crediting non-responders', () => {
  const input = session(); input.players.b.isEliminated = true; input.players.b.voluntaryExit = true;
  const result = calculateRound(input, { b: correct.b }, ['a', 'b'], () => 0);
  assert.equal(result.lastRoundResult.opponentLeft, true);
  assert.equal(result.players.a.correctAnswers, 0);
  assert.equal(result.players.b.correctAnswers, 1);
  assert.equal(result.players.b.totalAnswers, 1);
  const absent = calculateRound(input, {}, ['a', 'b'], () => 0);
  assert.equal(absent.players.b.totalAnswers, 0);
});

test('archive preserves every round and ranks voluntary departures below elimination ties', () => {
  const input = session();
  input.players.a = { ...input.players.a, isEliminated: true, eliminationRound: 0, voluntaryExit: true };
  input.players.b = { ...input.players.b, isEliminated: true, eliminationRound: 0 };
  input.rounds = [calculateRound(session(), correct, ['a', 'b'], () => 0).round];
  input.createdAt = Timestamp.fromMillis(1000);
  const result = buildArchive('game', input, new Date(9000));
  assert.deepEqual(result.rounds, input.rounds);
  assert.equal(result.playerResults[0].uid, 'b');
  assert.equal(result.sessionStartTime, new Date(1000).toISOString());
  assert.equal(result.statsApplied, true);
});

test('scheduler retries use the same task ID and absolute deadline', async () => {
  const calls = [];
  const enqueue = createTaskScheduler(name => ({ async enqueue(data, options) { calls.push({ name, data, options }); } }));
  const data = { sessionId: 's', roundIndex: 0, deadlineMs: 5000 };
  await enqueue('timeout', data, 5000); await enqueue('timeout', data, 5000);
  await enqueue('advance', data, 5000);
  assert.equal(calls[0].options.id, calls[1].options.id);
  assert.notEqual(calls[0].options.id, calls[2].options.id);
  assert.equal(calls[0].options.scheduleTime.getTime(), 5000);
  assert.match(calls[0].name, /roundTimeoutQueue$/);
});

test('scheduler ignores only an already-existing task; network failures remain retryable', async () => {
  let code = 'functions/task-already-exists';
  const enqueue = createTaskScheduler(() => ({ async enqueue() { throw Object.assign(new Error('enqueue failed'), { code }); } }));
  await enqueue('cleanup', { sessionId: 's' }, 5000);
  code = 'unavailable';
  await assert.rejects(enqueue('cleanup', { sessionId: 's' }, 5000), /enqueue failed/);
});
