'use strict';

const { FieldValue, Timestamp } = require('firebase-admin/firestore');
const { activeUids, calculateRound, buildArchive } = require('./round_logic');

const DISPLAY_MS = 5000;
function newCounter(uids) {
  return { eligibleUids: uids, validatedCount: 0, targetCount: uids.length,
    incorrectUids: [], validatedUids: [], resolved: false };
}
function roundTiming(now, seconds) {
  return { roundStartedAt: Timestamp.fromMillis(now), roundDeadline: Timestamp.fromMillis(now + seconds * 1000) };
}

function createGameLifecycle({ db, enqueue, now = Date.now, random = Math.random }) {
  const refFor = id => db.collection('sessions').doc(id);

  async function resolveRound(sessionId, expectedIndex, expectedDeadline) {
    const ref = refFor(sessionId);
    return db.runTransaction(async tx => {
      const session = (await tx.get(ref)).data();
      if (!session || session.status !== 'inProgress' || session.phase !== 'answering'
        || session.currentQuestionIndex !== expectedIndex) return false;
      const deadline = session.roundDeadline.toMillis();
      if (expectedDeadline != null && deadline !== expectedDeadline) return false;
      if (expectedDeadline != null && now() < deadline) throw new Error('Round deadline has not elapsed; retry task');
      const counterRef = ref.collection('roundCounters').doc(String(expectedIndex));
      const counter = (await tx.get(counterRef)).data();
      if (!counter || counter.resolved) return false;
      const answersSnap = await tx.get(ref.collection('answers').where('roundIndex', '==', expectedIndex));
      const answers = {};
      for (const doc of answersSnap.docs) {
        const answer = doc.data();
        if (answer.validatedAt && counter.validatedUids.includes(answer.uid)
          && answer.questionId === session.questionIds[expectedIndex]) answers[answer.uid] = answer;
      }
      const active = activeUids(session.players);
      if (active.length > 1 && now() < deadline && !active.every(uid => answers[uid])) return false;
      const result = calculateRound(session, answers, counter.eligibleUids, random);
      tx.update(ref, { players: result.players, activePlayerCount: result.activePlayerCount,
        lastRoundResult: result.lastRoundResult, rounds: [...session.rounds, result.round],
        phase: 'resolving', resolveAt: Timestamp.fromMillis(now() + DISPLAY_MS) });
      tx.update(counterRef, { resolved: true, targetCount: active.length });
      return true;
    });
  }

  // Archive, settlement marker, profile increments and result readiness are one
  // atomic commit. A retry cannot observe only some of these writes.
  async function finalizeInTransaction(tx, ref, session) {
    const archiveRef = db.collection('sessions_archive').doc(ref.id);
    const existing = (await tx.get(archiveRef)).data();
    if (existing && existing.statsApplied !== true) throw new Error('Legacy archive requires settlement migration');
    if (!existing) {
      const archive = buildArchive(ref.id, session, new Date(now()));
      tx.create(archiveRef, archive);
      for (const player of archive.playerResults) {
        const updates = { totalQuestionsAnswered: FieldValue.increment(player.totalAnswers),
          correctAnswers: FieldValue.increment(player.correctAnswers) };
        if (archive.gameMode === 'ranked') {
          updates.rankedGamesPlayed = FieldValue.increment(1);
          if (player.placement === 1) updates.rankedGamesWon = FieldValue.increment(1);
        }
        tx.update(db.collection('users').doc(player.uid), updates);
      }
    }
    tx.update(ref, { status: 'finished', phase: 'finished', resultsReady: true,
      endTime: existing ? Timestamp.fromDate(new Date(existing.endTime)) : Timestamp.fromMillis(now()) });
  }

  async function advanceRound(sessionId, expectedIndex, expectedResolveAt) {
    const ref = refFor(sessionId);
    return db.runTransaction(async tx => {
      const session = (await tx.get(ref)).data();
      if (!session || session.status !== 'inProgress' || session.phase !== 'resolving'
        || session.currentQuestionIndex !== expectedIndex || session.resolveAt.toMillis() !== expectedResolveAt) return false;
      if (now() < expectedResolveAt) throw new Error('Result display has not elapsed; retry task');
      const active = activeUids(session.players);
      const next = expectedIndex + 1;
      if (active.length <= 1 || next >= session.questionIds.length) {
        await finalizeInTransaction(tx, ref, session);
      } else {
        tx.create(ref.collection('roundCounters').doc(String(next)), newCounter(active));
        tx.update(ref, { phase: 'answering', currentQuestionIndex: next, lastRoundResult: null,
          resolveAt: null, ...roundTiming(now(), session.questionTimeLimit) });
      }
      return true;
    });
  }

  async function deleteWorkingData(ref) {
    for (const name of ['answers', 'roundCounters']) {
      let page;
      do {
        page = await ref.collection(name).limit(200).get();
        if (!page.empty) {
          const batch = db.batch();
          for (const doc of page.docs) batch.delete(doc.ref);
          await batch.commit();
        }
      } while (!page.empty);
    }
  }

  async function cleanup(sessionId) {
    const ref = refFor(sessionId);
    const session = (await ref.get()).data();
    if (session) {
      if (session.status !== 'finished' || session.resultsReady !== true) return;
      const archive = (await db.collection('sessions_archive').doc(sessionId).get()).data();
      if (archive?.statsApplied !== true) throw new Error('Cannot clean up an unsettled session');
    }
    await deleteWorkingData(ref);
    await ref.delete();
  }

  async function reconcile(sessionId) {
    const ref = refFor(sessionId);
    let session = (await ref.get()).data();
    if (!session) { await deleteWorkingData(ref); return; }
    if (session.status === 'waiting') return;
    if (session.status === 'inProgress' && session.phase === 'answering') {
      await resolveRound(sessionId, session.currentQuestionIndex);
      session = (await ref.get()).data();
    }
    if (!session) return;
    if (session.status === 'finished') {
      // Even 'finished' alone is not proof that archive/stat writes succeeded.
      if (session.resultsReady !== true) {
        await db.runTransaction(async tx => {
          const fresh = (await tx.get(ref)).data();
          if (fresh && fresh.status === 'finished' && fresh.resultsReady !== true) {
            await finalizeInTransaction(tx, ref, fresh);
          }
        });
      }
      await enqueue('cleanup', { sessionId }, now());
    } else if (session.phase === 'answering') {
      const deadlineMs = session.roundDeadline.toMillis();
      await enqueue('timeout', { sessionId, roundIndex: session.currentQuestionIndex, deadlineMs }, deadlineMs);
    } else if (session.phase === 'resolving') {
      const deadlineMs = session.resolveAt.toMillis();
      await enqueue('advance', { sessionId, roundIndex: session.currentQuestionIndex, deadlineMs }, deadlineMs);
    }
  }

  return { resolveRound, advanceRound, cleanup, reconcile };
}

module.exports = { createGameLifecycle, roundTiming, newCounter, DISPLAY_MS };
