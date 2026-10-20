'use strict';

const { onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onTaskDispatched }                      = require('firebase-functions/v2/tasks');
const { setGlobalOptions }                      = require('firebase-functions/v2');
const admin                                     = require('firebase-admin');
const { getFunctions }                          = require('firebase-admin/functions');
const { onCall, HttpsError }                     = require('firebase-functions/v2/https');
const { createGameCommands, CommandError }        = require('./game_commands');

setGlobalOptions({ region: 'europe-central2' });

admin.initializeApp();

const db   = admin.firestore();
const rtdb = admin.database();

const commands = createGameCommands({ db, rtdb });
for (const [name, command] of Object.entries(commands)) {
  exports[name] = onCall(async request => {
    if (!request.auth) throw new HttpsError('unauthenticated', 'Sign in first');
    if (!request.data || typeof request.data !== 'object' || Array.isArray(request.data)) {
      throw new HttpsError('invalid-argument', 'Expected an object');
    }
    try { return await command(request.auth.uid, request.data); }
    catch (error) {
      if (error instanceof CommandError) throw new HttpsError(error.code, error.message);
      throw error;
    }
  });
}

const { createGameLifecycle } = require('./game_lifecycle');
const { createTaskScheduler } = require('./task_scheduler');
const lifecycle = createGameLifecycle({ db,
  enqueue: createTaskScheduler(name => getFunctions().taskQueue(name)) });

// Re-read persisted state rather than trusting an old/reordered event snapshot.
exports.onCounterUpdate = onDocumentWritten(
  { document: 'sessions/{sessionId}/roundCounters/{roundIndex}', retry: true },
  async event => {
    if (event.data.after.exists) await lifecycle.reconcile(event.params.sessionId);
  },
);
exports.onSessionWrite = onDocumentWritten(
  { document: 'sessions/{sessionId}', retry: true },
  async event => lifecycle.reconcile(event.params.sessionId),
);

const taskOptions = {
  retryConfig: { maxAttempts: 100, maxRetrySeconds: 86400,
    minBackoffSeconds: 1, maxBackoffSeconds: 60, maxDoublings: 6 },
  rateLimits: { maxConcurrentDispatches: 20 },
};
exports.roundTimeoutQueue = onTaskDispatched(taskOptions, async request => {
  const { sessionId, roundIndex, deadlineMs } = request.data;
  await lifecycle.resolveRound(sessionId, roundIndex, deadlineMs);
  await lifecycle.reconcile(sessionId);
});
exports.roundAdvanceQueue = onTaskDispatched(taskOptions, async request => {
  const { sessionId, roundIndex, deadlineMs } = request.data;
  await lifecycle.advanceRound(sessionId, roundIndex, deadlineMs);
  await lifecycle.reconcile(sessionId);
});
exports.sessionCleanupQueue = onTaskDispatched(taskOptions, async request => {
  await lifecycle.cleanup(request.data.sessionId);
});
