'use strict';

function isDatabaseKey(value) {
  return typeof value === 'string' && value.length > 0
    && !/[.#$\[\]/\u0000-\u001f\u007f]/.test(value);
}

async function validateRoundAnswer(rtdb, session, roundIndex, questionId, answer) {
  const expectedId = session.questionIds?.[roundIndex];
  if (!Number.isInteger(roundIndex) || roundIndex < 0
    || roundIndex !== session.currentQuestionIndex
    || !isDatabaseKey(session.categoryId) || !isDatabaseKey(expectedId)
    || questionId !== expectedId || typeof answer !== 'string') return false;

  const snap = await rtdb.ref(`questions/${session.categoryId}/${expectedId}`).get();
  if (!snap.exists()) throw new Error(`Missing question: ${session.categoryId}/${expectedId}`);
  const correct = snap.val()?.correctAnswers;
  if (!Array.isArray(correct)) throw new Error(`Invalid question: ${expectedId}`);
  return correct.includes(answer);
}

module.exports = { validateRoundAnswer };
