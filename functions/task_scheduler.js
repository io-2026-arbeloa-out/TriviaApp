'use strict';

const { createHash } = require('node:crypto');
const queues = { timeout: 'roundTimeoutQueue', advance: 'roundAdvanceQueue', cleanup: 'sessionCleanupQueue' };

function createTaskScheduler(queueFor) {
  return async (kind, data, due) => {
    // Cleanup has one identity per session, regardless of the event retry time.
    const identity = `${kind}:${data.sessionId}:${data.roundIndex ?? ''}:${data.deadlineMs ?? ''}`;
    const id = createHash('sha256').update(identity).digest('hex');
    try {
      await queueFor(`locations/europe-central2/functions/${queues[kind]}`).enqueue(data, {
        id, scheduleTime: new Date(due),
      });
    } catch (error) {
      if (error.code !== 'functions/task-already-exists') throw error;
    }
  };
}

module.exports = { createTaskScheduler };
