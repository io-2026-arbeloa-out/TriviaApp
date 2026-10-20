import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/question_type.dart';

void main() {
  test('question types retain their Firebase representation', () {
    const expected = ['true_false', 'open4', 'open6', 'open', 'mixed'];
    expect(QuestionType.values.map((type) => type.toJson()), expected);
    for (final value in expected) {
      expect(QuestionType.fromJson(value).toJson(), value);
    }
    expect(QuestionType.fromJson(null), QuestionType.mixed);
    expect(QuestionType.fromJson('unknown'), QuestionType.mixed);
  });

  test('a true/false question round-trips without changing its wire type', () {
    final data = {
      'id': '01',
      'text': 'Question?',
      'answers': ['True', 'False'],
      'type': 'true_false',
      'difficulty': 'easy',
    };
    final question = Question.fromJson(data);
    expect(question.type, QuestionType.trueFalse);
    expect(question.toJson(), data);
  });
}
