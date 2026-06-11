'use strict';

const { onDocumentCreated, onDocumentWritten } = require('firebase-functions/v2/firestore');
const { onTaskDispatched }                      = require('firebase-functions/v2/tasks');
const { setGlobalOptions }                      = require('firebase-functions/v2');
const admin                                     = require('firebase-admin');
const { getFunctions }                          = require('firebase-admin/functions');

setGlobalOptions({ region: 'europe-central2' });

admin.initializeApp();

const db   = admin.firestore();
const rtdb = admin.database();
const FV   = admin.firestore.FieldValue;

const RESOLVE_DISPLAY_MS = 5_000;
const ROUND_TIMEOUT_MS   = 30_000;

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
  const correct  = question?.correctAnswers || [];
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

/**
 * Zlicza ile kolejnych rund z konca tablicy rounds mialo eliminatedUid === null
 * (wszyscy odpowiedzieli poprawnie). Uzywane do wykrycia serii 3 z rzedu.
 */
function countAllCorrectStreak(rounds) {
  let streak = 0;
  for (let i = (rounds || []).length - 1; i >= 0; i--) {
    if (rounds[i].eliminatedUid == null) streak++;
    else break;
  }
  return streak;
}

// ─────────────────────────────────────────────────────────────────────────────
// enqueueRoundTimeout — planuje Cloud Task po ROUND_TIMEOUT_MS
// ─────────────────────────────────────────────────────────────────────────────
async function enqueueRoundTimeout(sessionId, roundIndex) {
  const queue = getFunctions().taskQueue(
    `locations/europe-central2/functions/roundTimeoutQueue`,
  );
  await queue.enqueue(
    { sessionId, roundIndex },
    { scheduleDelaySeconds: Math.floor(ROUND_TIMEOUT_MS / 1000) },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// tryResolveFromCounter — shared entry when counter may have reached target
// ─────────────────────────────────────────────────────────────────────────────
async function tryResolveFromCounter(sessionId, roundIndex, counterData, session, sessionRef) {
  if (!counterData || counterData.resolved === true) return;

  if (session.status !== 'inProgress') return;
  if (session.phase  !== 'answering')  return;
  if (session.currentQuestionIndex !== roundIndex) return;

  // FIX: countActivePlayers jako ostateczny fallback gdy targetCount i
  // activePlayerCount nie są ustawione (np. dla rundy 0 bez pre-inicjalizacji)
  const target = counterData.targetCount
    || session.activePlayerCount
    || countActivePlayers(session.players)
    || 0;

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
    const answerRef     = event.data.ref;
    const answerData    = event.data.data();
    if (!answerData) return;

    const { uid, roundIndex, questionId, answer } = answerData;
    if (uid == null || roundIndex == null || questionId == null || answer == null) return;
    if (answerData.validatedAt != null) return;

    const sessionRef  = db.collection('sessions').doc(sessionId);
    const sessionSnap = await sessionRef.get();
    if (!sessionSnap.exists) return;

    const session = sessionSnap.data();
    if (session.status !== 'inProgress') return;
    if (session.phase  !== 'answering')  return;
    if (session.currentQuestionIndex !== roundIndex) return;

    const player = session.players?.[uid];
    if (!player || player.isEliminated) return;

    const isCorrect = await validateAnswerViaRtdb(
      session.categoryId,
      String(questionId),
      answer,
    );

    const counterRef    = sessionRef.collection('roundCounters').doc(String(roundIndex));
    const counterUpdate = { validatedCount: FV.increment(1) };
    if (!isCorrect) {
      counterUpdate.incorrectUids = FV.arrayUnion(uid);
    }

    // FIX: transakcja z validatedUids zapobiega wielokrotnemu zliczeniu odpowiedzi
    // tego samego gracza. Dodatkowo inicjalizuje targetCount jeśli nie jest ustawiony
    // (zabezpieczenie dla rundy 0 gdy Flutter nie pre-inicjalizuje countera).
    try {
      await db.runTransaction(async (tx) => {
        const counterSnap = await tx.get(counterRef);
        const counter     = counterSnap.data() || {};

        if ((counter.validatedUids || []).includes(uid)) throw skip;

        // FIX: defensywna inicjalizacja targetCount przy pierwszej odpowiedzi
        if (!counter.targetCount) {
          counterUpdate.targetCount = countActivePlayers(session.players);
        }

        tx.update(answerRef, { isCorrect, validatedAt: FV.serverTimestamp() });
        tx.set(counterRef, {
          ...counterUpdate,
          validatedUids: FV.arrayUnion(uid),
        }, { merge: true });
      });
    } catch (e) {
      if (e === skip) return;
      throw e;
    }
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

  // Gdy zostało 1 lub 0 aktywnych graczy (np. po wyjściu gracza z gry),
  // nie ma kogo eliminować — kończymy grę bez fazy 'resolving'.
  // Dzięki temu pozostały gracz nie zobaczy fałszywego komunikatu "odpadłeś".
  if (activeUids.length <= 1) {
    // Zostal 1 lub 0 aktywnych graczy (np. po wyjsciu gracza z gry).
    // Idziemy przez faze 'resolving' z opponentLeft: true, zeby klient mogl
    // wyswietlic komunikat "Twoj przeciwnik opuscil gre. Wygrales!".
    const statsUpdates = {};
    for (const uid of activeUids) {
      statsUpdates[`players.${uid}.totalAnswers`] = FV.increment(1);
      if (!incorrectUids.includes(uid)) {
        statsUpdates[`players.${uid}.correctAnswers`] = FV.increment(1);
      }
    }
    try {
      await db.runTransaction(async (tx) => {
        const snap = await tx.get(sessionRef);
        const data = snap.data();
        if (!data || data.phase !== 'answering') throw skip;
        if (data.currentQuestionIndex !== roundIndex) throw skip;
        const cSnap = await tx.get(counterRef);
        if (cSnap.data()?.resolved === true) throw skip;
        tx.update(sessionRef, {
          ...statsUpdates,
          phase: 'resolving',
          lastRoundResult: {
            eliminatedUid:      null,
            eliminatedUsername: null,
            lotteryOccurred:    false,
            lotteryPool:        {},
            opponentLeft:       true,
          },
        });
        tx.set(counterRef, { resolved: true }, { merge: true });
      });
    } catch (e) {
      if (e === skip) return;
      throw e;
    }
    await deleteAnswersForRound(sessionRef, roundIndex);
    await new Promise(r => setTimeout(r, RESOLVE_DISPLAY_MS));
    const freshSnap = await sessionRef.get();
    const fresh     = freshSnap.data();
    if (fresh && fresh.status === 'inProgress') {
      await finishGame(sessionRef, fresh, { roundIndex, answerDetails: {}, isCorrectMap: {} });
    }
    return;
  }

  let eliminatedUid   = null;
  let lotteryOccurred = false;
  let lotteryPool     = {}; // FIX: map<uid, ticketCount> zamiast string[]

  const incorrectActive = incorrectUids.filter(uid => activeUids.includes(uid));

  if (incorrectActive.length === 0) {
    // Wszyscy odpowiedzieli poprawnie — sprawdz serie.
    // Loteria odpala sie dopiero po 3 kolejnych rundach bez zadnej blednej odpowiedzi.
    // Streak jest implicite zakodowany w session.rounds: liczba konowych rekordow
    // z eliminatedUid === null.
    const streak = countAllCorrectStreak(session.rounds);
    if (streak + 1 >= 3) {
      // Trzecia runda z rzedu bez bledu — loteria wsrod wszystkich aktywnych graczy.
      // Kazdy ktory przezye dostanie +1 bilet (standardowa mechanika).
      lotteryOccurred = true;
      for (const uid of activeUids) {
        lotteryPool[uid] = playersMap[uid]?.lotteryTickets || 0;
      }
      eliminatedUid = weightedRandom(
        Object.entries(lotteryPool).map(([uid, tickets]) => ({ uid, lotteryTickets: tickets })),
      );
    }
    // streak < 2: eliminatedUid zostaje null, runda przechodzi bez eliminacji
  } else if (incorrectActive.length === 1) {
    eliminatedUid = incorrectActive[0];
  } else {
    lotteryOccurred = true;
    for (const uid of incorrectActive) {
      lotteryPool[uid] = playersMap[uid]?.lotteryTickets || 0;
    }
    eliminatedUid = weightedRandom(
      Object.entries(lotteryPool).map(([uid, tickets]) => ({ uid, lotteryTickets: tickets })),
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
    rounds: FV.arrayUnion({
      roundIndex,
      questionId:      (session.questionIds || [])[roundIndex] || '',
      eliminatedUid,
      lotteryOccurred,
      lotteryPool,
    }),
  };

  if (eliminatedUid) {
    updates[`players.${eliminatedUid}.isEliminated`]     = true;
    updates[`players.${eliminatedUid}.eliminationRound`] = roundIndex;
    updates['activePlayerCount']                          = FV.increment(-1);
  }

  if (lotteryOccurred && eliminatedUid) {
    // FIX: iteracja po Object.keys() zamiast po tablicy stringów
    for (const uid of Object.keys(lotteryPool)) {
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
      const counter     = counterSnap.data();
      if (counter?.resolved === true) throw skip;

      tx.update(sessionRef, updates);
      // FIX: set zamiast update — update rzuca NOT_FOUND gdy roundCounters/N
      // nie istnieje (np. gdy deployed CF używa roundProgress zamiast subkolekcji)
      tx.set(counterRef, { resolved: true }, { merge: true });
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
      answerDetails[d.uid] = d.answer    || '';
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
        validatedUids:  [],
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
    if (a.eliminationRound !== b.eliminationRound) return b.eliminationRound - a.eliminationRound;
    // Ta sama runda: dobrowolne wyjscie (voluntaryExit) rankuje nizej niz formalna eliminacja
    if (a.voluntaryExit && !b.voluntaryExit) return  1;
    if (!a.voluntaryExit && b.voluntaryExit) return -1;
    return 0;
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
      lotteryPool:     r.lotteryPool     || {}, // FIX: {} zamiast []
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

  const roundIndex  = session.currentQuestionIndex ?? 0;
  const activeCount = countActivePlayers(session.players);

  const counterRef  = sessionRef.collection('roundCounters').doc(String(roundIndex));
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
// handleRoundTimeout — logika wywoływana przez Cloud Task po upływie czasu
// ─────────────────────────────────────────────────────────────────────────────
async function handleRoundTimeout(sessionId, roundIndex) {
  const sessionRef  = db.collection('sessions').doc(sessionId);
  const sessionSnap = await sessionRef.get();
  if (!sessionSnap.exists) return;

  const session = sessionSnap.data();
  if (session.status !== 'inProgress') return;
  if (session.phase  !== 'answering')  return;
  if (session.currentQuestionIndex !== roundIndex) return;

  const counterRef  = sessionRef.collection('roundCounters').doc(String(roundIndex));
  const counterSnap = await counterRef.get();
  if (!counterSnap.exists) return;

  const counter = counterSnap.data();
  if (counter.resolved === true) return;

  // Gracze którzy nie odpowiedzieli w czasie są traktowani jako błędna odpowiedź
  const validatedUids = counter.validatedUids || [];
  const playersMap    = session.players       || {};
  const activeUids    = Object.keys(playersMap).filter(uid => !playersMap[uid].isEliminated);
  const nonResponders = activeUids.filter(uid => !validatedUids.includes(uid));

  const incorrectUids = [
    ...normalizeIncorrectUids(counter.incorrectUids),
    ...nonResponders,
  ];

  await resolveRound(
    sessionId,
    roundIndex,
    [...new Set(incorrectUids)],
    session,
    sessionRef,
    counter,
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// 3. onSessionWrite — cleanup + leave sync + enqueue timeout
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

    // Enqueue timeout przy każdym przejściu do fazy 'answering':
    // - start pierwszej rundy (np. 'waiting' → 'answering')
    // - przejście do kolejnej rundy ('resolving' → 'answering')
    if (
      data.status === 'inProgress' &&
      data.phase  === 'answering'  &&
      before?.phase !== 'answering'
    ) {
      await enqueueRoundTimeout(event.params.sessionId, data.currentQuestionIndex ?? 0);
    }

    if (
      before &&
      data.status === 'inProgress' &&
      data.phase  === 'answering' &&
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

// ─────────────────────────────────────────────────────────────────────────────
// 4. roundTimeoutQueue — Cloud Tasks handler
// ─────────────────────────────────────────────────────────────────────────────
exports.roundTimeoutQueue = onTaskDispatched(
  {
    retryConfig: { maxAttempts: 1 },
    rateLimits:  { maxConcurrentDispatches: 20 },
  },
  async (req) => {
    const { sessionId, roundIndex } = req.data;
    await handleRoundTimeout(sessionId, parseInt(roundIndex, 10));
  },
);