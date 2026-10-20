'use strict';

const { test } = require('node:test');
const assert = require('node:assert/strict');
const fixture = require('../../test/fixtures/public_question_contract.json');
const { validateRoundAnswer } = require('../question_contract');

function database(data = fixture) {
  const paths = [];
  return {
    paths,
    ref(path) {
      paths.push(path);
      const value = path.split('/').reduce((node, key) => node?.[key], data);
      return { async get() { return { exists: () => value != null, val: () => value }; } };
    },
  };
}

function session(id) {
  return { categoryId: 'general', questionIds: [id], currentQuestionIndex: 0 };
}

for (const [id, question] of Object.entries(fixture.answer_keys.general)) {
  test(`validates exact RTDB key ${id}`, async () => {
    const db = database();
    assert.equal(await validateRoundAnswer(db, session(id), 0, id, question.correctAnswers[0]), true);
    assert.deepEqual(db.paths, [`answer_keys/general/${id}`]);
    assert.equal(await validateRoundAnswer(db, session(id), 0, id, 'incorrect'), false);
  });
}

test('rejects a different question, round or unsafe key before reading RTDB', async () => {
  const db = database();
  assert.equal(await validateRoundAnswer(db, session('01'), 0, '1', '6'), false);
  assert.equal(await validateRoundAnswer(db, session('01'), 1, '01', '4'), false);
  assert.equal(await validateRoundAnswer(db, session('../other'), 0, '../other', '4'), false);
  assert.equal(await validateRoundAnswer(db, session('01'), 0, '01', null), false);
  assert.deepEqual(db.paths, []);
});

test('missing or malformed question is a contract error', async () => {
  await assert.rejects(validateRoundAnswer(database(), session('missing'), 0, 'missing', '4'), /Missing question/);
  const db = database({ answer_keys: { general: { broken: { text: 'No answer key' } } } });
  await assert.rejects(validateRoundAnswer(db, session('broken'), 0, 'broken', '4'), /Invalid question/);
});
