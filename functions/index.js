'use strict';

const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { setGlobalOptions }                      = require('firebase-functions/v2');
const admin                                     = require('firebase-admin');

// Must match the region where Firestore lives.
// Check: Firebase Console → Firestore → your database URL or location badge.
setGlobalOptions({ region: 'europe-central2' });

admin.initializeApp();

const db = admin.firestore();
const FV   = admin.firestore.FieldValue;

const RESOLVE_DISPLAY_MS = 5_000; // ms clients spend on the resolving screen

// ─────────────────────────────────────────────────────────────────────────────
// Weighted lottery: each player's weight = lotteryTickets + 1
// ─────────────────────────────────────────────────────────────────────────────
function weightedRandom(pool) {
  // pool: [{ uid, lotteryTickets }, ...]
  const weights = pool.map(p => (p.lotteryTickets || 0) + 1);
  const total   = weights.reduce((a, b) => a + b, 0);
  let   r       = Math.random() * total;
  for (let i = 0; i < pool.length; i++) {
    r -= weights[i];
    if (r <= 0) return pool[i].uid;
  }
  return pool[pool.length - 1].uid;
}

// ─────────────────────────────────────────────────────────────────────────────
// 1.  onAnswerCreate
//     Triggered when a player writes an answer document.
//     • Validates the answer against Realtime Database.
//     • Writes isCorrect back to the answer doc.
//     • Increments the round counter (set+merge — creates doc if missing).
// ─────────────────────────────────────────────────────────────────────────────
exports.onAnswerCreate = onDocumentCreated(
  'sessions/{sessionId}/answers/{answerId}',
  async (event) => {
    const { sessionId } = event.params;
    const { uid, roundIndex, questionId, answer } = event.data.data();

    // 1. Read session to get categoryId (1 CF Firestore read).
    const sessionRef  = db.collection('sessions').doc(sessionId);
    const sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) return;

    const session = sessionSnap.data();
    if (session.status !== 'inProgress') return;

    // 2. Validate answer against Firestore questions.
    //    If the question document is missing, treat the answer as incorrect
    //    so the round still progresses instead of hanging indefinitely.
    let isCorrect = false;
    const qSnap = await db.collection('questions').doc(questionId).get();
    if (qSnap.exists) {
      const question = qSnap.data();
      isCorrect = (question.correctAnswers || []).includes(answer);
    }

    // 3. Increment the round counter atomically.
    //    set+merge creates the doc if it doesn't exist yet (race-safe).
    const counterRef    = sessionRef.collection('roundCounters').doc(String(roundIndex));
    const counterUpdate = { validatedCount: FV.increment(1) };
    if (!isCorrect) {
      counterUpdate.incorrectUids = FV.arrayUnion([uid]);
    }
    await counterRef.set(counterUpdate, { merge: true });
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// 2.  onCounterUpdate
//     Triggered on every write to a roundCounters document.
//     Resolves the round when validatedCount reaches activePlayerCount.
//
//     Multiple invocations fire per round (one per answer), but only the one
//     where the count first crosses the threshold proceeds — the transaction
//     inside resolveRound guards against duplicate resolution.
// ─────────────────────────────────────────────────────────────────────────────
exports.onCounterUpdate = onDocumentWritten(
  'sessions/{sessionId}/roundCounters/{roundIndex}',
  async (event) => {
    const after = event.data.after.data();
    if (!after) return; // document deleted

    const { sessionId, roundIndex } = event.params;
    const rIdx = parseInt(roundIndex, 10);

    // Read session to get activePlayerCount and verify current state
    // (1 CF read per invocation; unavoidable without a separate targetCount
    // field — see architecture notes in FIREBASE_SETUP.md).
    const sessionRef  = db.collection('sessions').doc(sessionId);
    const sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) return;

    const session = sessionSnap.data();
    if (session.status !== 'inProgress')          return;
    if (session.phase  !== 'answering')            return;
    if (session.currentQuestionIndex !== rIdx)     return; // stale trigger

    // targetCount is written into the counter document by joinSession (Dart)
    // and by resolveRound (CF) for subsequent rounds.  It reflects the exact
    // number of players expected to answer this round, so we don't have to
    // trust session.activePlayerCount which may not be updated yet.
    const target = after.targetCount || session.activePlayerCount || 0;
    if ((after.validatedCount || 0) < target)      return; // not everyone answered yet

    await resolveRound(
      sessionId, rIdx,
      after.incorrectUids || [],
      session,
      sessionRef,
    );
  },
);

// ─────────────────────────────────────────────────────────────────────────────
// resolveRound
//   • Computes lottery if needed.
//   • Atomically updates the session document (phase → resolving, player
//     stats, lastRoundResult, rounds[]).
//   • Waits RESOLVE_DISPLAY_MS so clients can show the result screen.
//   • Either advances to the next round (creates next roundCounter) or
//     finishes the game.
// ─────────────────────────────────────────────────────────────────────────────
async function resolveRound(sessionId, roundIndex, incorrectUids, session, sessionRef) {
  const playersMap  = session.players || {};
  const activeUids  = Object.keys(playersMap).filter(uid => !playersMap[uid].isEliminated);

  // Determine elimination.
  let eliminatedUid      = null;
  let lotteryOccurred    = false;
  let lotteryPool        = [];

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

  // Build atomic update for the session document.
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
      questionId:      (session.questionIds || [])[roundIndex] || '',
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

  // Increment lotteryTickets for lottery survivors.
  if (lotteryOccurred && eliminatedUid) {
    for (const uid of lotteryPool) {
      if (uid !== eliminatedUid) {
        updates[`players.${uid}.lotteryTickets`] = FV.increment(1);
      }
    }
  }

  // Update answer stats for every active player.
  for (const uid of activeUids) {
    updates[`players.${uid}.totalAnswers`] = FV.increment(1);
    if (!incorrectActive.includes(uid)) {
      updates[`players.${uid}.correctAnswers`] = FV.increment(1);
    }
  }

  // Atomically write — transaction prevents duplicate resolution when multiple
  // onCounterUpdate invocations fire simultaneously.
  const skip = new Error('SKIP');
  try {
    await db.runTransaction(async (tx) => {
      const snap = await tx.get(sessionRef);
      const data = snap.data();
      if (!data || data.phase !== 'answering')        throw skip;
      if (data.currentQuestionIndex !== roundIndex)   throw skip;
      tx.update(sessionRef, updates);
    });
  } catch (e) {
    if (e === skip) return;
    throw e;
  }

  // Wait for clients to display the resolving screen before advancing.
  await new Promise(r => setTimeout(r, RESOLVE_DISPLAY_MS));

  // Re-read so we have the post-elimination activePlayerCount.
  const freshSnap      = await sessionRef.get();
  const fresh          = freshSnap.data();
  const newActiveCount = fresh.activePlayerCount || 0;
  const nextIndex      = roundIndex + 1;
  const totalQuestions = (fresh.questionIds || []).length;

  if (newActiveCount <= 1 || nextIndex >= totalQuestions) {
    await finishGame(sessionRef, fresh);
  } else {
    // Create next round counter before flipping phase so fast players can
    // submit answers as soon as they see the new question.
    await sessionRef
      .collection('roundCounters')
      .doc(String(nextIndex))
      .set({ validatedCount: 0, targetCount: newActiveCount, incorrectUids: [] }, { merge: true });

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
async function finishGame(sessionRef, sessionData) {
  const skip = new Error('SKIP');
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

  await buildArchive(sessionRef.id, sessionData);
}

async function buildArchive(sessionId, session) {
  const playersMap = session.players || {};

  // Sort: winner first (eliminationRound == null), then latest elimination.
  const sorted = Object.entries(playersMap).sort(([, a], [, b]) => {
    if (a.eliminationRound == null && b.eliminationRound == null) return 0;
    if (a.eliminationRound == null) return -1;
    if (b.eliminationRound == null) return  1;
    return b.eliminationRound - a.eliminationRound;
  });

  const playerResults = sorted.map(([uid, p], i) => ({
    uid,
    username:        p.username        || '',
    placement:       i + 1,
    correctAnswers:  p.correctAnswers  || 0,
    totalAnswers:    p.totalAnswers    || 0,
    eliminationRound: p.eliminationRound ?? null,
    lotteryTimesIn:  p.lotteryTickets  || 0,
  }));

  const rounds = (session.rounds || []).map(r => ({
    roundIndex:      r.roundIndex,
    questionId:      r.questionId,
    playerAnswers:   {},   // text not stored in session doc; enrich if needed
    isCorrect:       {},
    lotteryOccurred: r.lotteryOccurred || false,
    lotteryPool:     r.lotteryPool     || [],
    eliminatedUid:   r.eliminatedUid   ?? null,
  }));

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
// deleteSubcollectionDocs
//   Batch-deletes all documents in a subcollection reference.
//   Firestore does NOT auto-delete subcollections when a parent document is
//   removed, so this must be called explicitly.
// ─────────────────────────────────────────────────────────────────────────────
async function deleteSubcollectionDocs(colRef) {
  const snap = await colRef.get();
  if (snap.empty) return;
  const batch = db.batch();
  snap.forEach(doc => batch.delete(doc.ref));
  await batch.commit();
}

// ─────────────────────────────────────────────────────────────────────────────
// 3.  onSessionWrite — safety-net cleanup
//     • When the session document is deleted (last player left via leaveGame
//       or removePlayer): cleans up the answers/ and roundCounters/
//       subcollections that Firestore leaves behind.
//     • When the document still exists but has no players: deletes both
//       subcollections and then the document itself (triggers this handler
//       once more, caught by the !after.exists branch above).
// ─────────────────────────────────────────────────────────────────────────────
exports.onSessionWrite = onDocumentWritten(
  'sessions/{sessionId}',
  async (event) => {
    const after  = event.data.after;
    const docRef = after.ref;

    if (!after.exists) {
      // Document was already deleted by the client transaction.
      // Clean up subcollections that Firestore left behind.
      await deleteSubcollectionDocs(docRef.collection('answers'));
      await deleteSubcollectionDocs(docRef.collection('roundCounters'));
      return;
    }

    const data = after.data();
    if ((data.playerUids || []).length > 0) return; // players still present

    // Empty session — clean up subcollections then the document.
    if (data.status === 'waiting' || data.status === 'inProgress') {
      await deleteSubcollectionDocs(docRef.collection('answers'));
      await deleteSubcollectionDocs(docRef.collection('roundCounters'));
      await docRef.delete();
    }
  },
);