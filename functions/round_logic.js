'use strict';

const activeUids = players => Object.keys(players).filter(uid => !players[uid].isEliminated);

// All inputs are transaction snapshots. Randomness is supplied by the caller.
function calculateRound(session, answers, eligibleUids, random) {
  const players = Object.fromEntries(Object.entries(session.players).map(([uid, p]) => [uid, { ...p }]));
  const active = activeUids(players);
  const incorrect = active.filter(uid => answers[uid]?.isCorrect !== true);
  let streak = 0;
  for (const round of [...session.rounds].reverse()) {
    if (round.eliminatedUid != null) break;
    streak++;
  }
  let pool = [];
  let eliminatedUid = null;
  if (active.length > 1) {
    if (incorrect.length === 1) eliminatedUid = incorrect[0];
    else if (incorrect.length > 1) pool = incorrect;
    else if (streak >= 2) pool = active;
  }
  const lotteryPool = Object.fromEntries(pool.map(uid => [uid, players[uid].lotteryTickets]));
  if (pool.length) {
    let ticket = random() * pool.reduce((sum, uid) => sum + players[uid].lotteryTickets + 1, 0);
    eliminatedUid = pool[pool.length - 1];
    for (const uid of pool) {
      ticket -= players[uid].lotteryTickets + 1;
      if (ticket <= 0) { eliminatedUid = uid; break; }
    }
    for (const uid of pool) if (uid !== eliminatedUid) players[uid].lotteryTickets++;
  }
  const playerAnswers = {}, isCorrect = {};
  for (const uid of eligibleUids) {
    playerAnswers[uid] = answers[uid]?.answer ?? '';
    isCorrect[uid] = answers[uid]?.isCorrect === true;
    // A departure without an answer is not a submitted attempt. An accepted
    // answer remains part of the player's statistics even if they then leave.
    if (active.includes(uid) || answers[uid]) {
      players[uid].totalAnswers++;
      if (isCorrect[uid]) players[uid].correctAnswers++;
    }
  }
  if (eliminatedUid) {
    players[eliminatedUid].isEliminated = true;
    players[eliminatedUid].eliminationRound = session.currentQuestionIndex;
  }
  const lastRoundResult = {
    eliminatedUid, eliminatedUsername: eliminatedUid ? players[eliminatedUid].username : null,
    lotteryOccurred: pool.length > 0, lotteryPool, opponentLeft: active.length <= 1,
  };
  return {
    players, activePlayerCount: activeUids(players).length, lastRoundResult,
    round: { roundIndex: session.currentQuestionIndex, questionId: session.questionIds[session.currentQuestionIndex],
      playerAnswers, isCorrect, ...lastRoundResult },
  };
}

function buildArchive(sessionId, session, endTime) {
  const sorted = Object.entries(session.players).sort(([, a], [, b]) => {
    if (a.eliminationRound == null && b.eliminationRound == null) return 0;
    if (a.eliminationRound == null) return -1;
    if (b.eliminationRound == null) return 1;
    return b.eliminationRound - a.eliminationRound || Number(!!a.voluntaryExit) - Number(!!b.voluntaryExit);
  });
  const iso = timestamp => timestamp?.toDate().toISOString() ?? endTime.toISOString();
  return {
    sessionId, participantUids: session.participantUids, categoryId: session.categoryId,
    questionIds: session.questionIds, gameMode: session.mode || 'casual',
    sessionStartTime: iso(session.createdAt), gameStartTime: iso(session.gameStartTime),
    endTime: endTime.toISOString(), rounds: session.rounds, statsApplied: true,
    playerResults: sorted.map(([uid, p], i) => ({ uid, username: p.username, profilePicture: p.profilePicture,
      placement: i + 1, correctAnswers: p.correctAnswers, totalAnswers: p.totalAnswers,
      eliminationRound: p.eliminationRound ?? null, lotteryTimesIn: p.lotteryTickets })),
  };
}

module.exports = { activeUids, calculateRound, buildArchive };
