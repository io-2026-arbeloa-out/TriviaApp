'use strict';

function splitQuestionBank(source) {
  const publicQuestions = {}; const answerKeys = {};
  for (const [category, questions] of Object.entries(source.questions || {})) {
    publicQuestions[category] = {}; answerKeys[category] = {};
    for (const [id, q] of Object.entries(questions)) {
      if (q == null) continue;
      if (!q || typeof q.text !== 'string' || !Array.isArray(q.correctAnswers)
        || !q.correctAnswers.length || !Array.isArray(q.wrongAnswers)
        || ![...q.correctAnswers, ...q.wrongAnswers].every(a => typeof a === 'string')) {
        throw new Error(`Invalid legacy question ${category}/${id}`);
      }
      const answers = [...new Set([...q.correctAnswers, ...q.wrongAnswers])].sort();
      if (answers.length < 2) throw new Error(`Not enough answer options ${category}/${id}`);
      publicQuestions[category][id] = { text: q.text, answers, type: q.type, difficulty: q.difficulty };
      answerKeys[category][id] = { correctAnswers: q.correctAnswers };
    }
  }
  return { public_questions: publicQuestions, answer_keys: answerKeys };
}

if (require.main === module) {
  const fs = require('node:fs');
  const [input, output] = process.argv.slice(2);
  if (!input || !output) throw new Error('Usage: node scripts/split_questions.js export.json split.json');
  fs.writeFileSync(output, JSON.stringify(splitQuestionBank(JSON.parse(fs.readFileSync(input, 'utf8').replace(/^\uFEFF/, ''))), null, 2), { flag: 'wx' });
}
module.exports = { splitQuestionBank };
