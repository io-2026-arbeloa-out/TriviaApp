/*
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';

void main() {
  group('SingleplayerGameOptions', () {
    // ── constructor defaults ────────────────────────────────────────────────

    group('constructor defaults', () {
      test('numQuestions defaults to 10', () {
        const opts = SingleplayerGameOptions();
        expect(opts.numQuestions, 10);
      });

      test('timePerQuestion defaults to 30', () {
        const opts = SingleplayerGameOptions();
        expect(opts.timePerQuestion, 30);
      });

      test('questionType defaults to null (mieszane)', () {
        const opts = SingleplayerGameOptions();
        expect(opts.questionType, isNull);
      });

      test('stores provided values correctly', () {
        const opts = SingleplayerGameOptions(
          numQuestions: 20,
          timePerQuestion: 15,
          questionType: QuestionType.open4,
        );

        expect(opts.numQuestions, 20);
        expect(opts.timePerQuestion, 15);
        expect(opts.questionType, QuestionType.open4);
      });

      test('timePerQuestion 0 is a valid value (brak limitu)', () {
        const opts = SingleplayerGameOptions(timePerQuestion: 0);
        expect(opts.timePerQuestion, 0);
      });
    });

    // ── copyWith ────────────────────────────────────────────────────────────

    group('copyWith', () {
      const base = SingleplayerGameOptions(
        numQuestions: 10,
        timePerQuestion: 30,
        questionType: QuestionType.open4,
      );

      test('returns new instance with updated numQuestions', () {
        final updated = base.copyWith(numQuestions: 20);
        expect(updated.numQuestions, 20);
      });

      test('preserves other fields when updating numQuestions', () {
        final updated = base.copyWith(numQuestions: 20);
        expect(updated.timePerQuestion, 30);
        expect(updated.questionType, QuestionType.open4);
      });

      test('returns new instance with updated timePerQuestion', () {
        final updated = base.copyWith(timePerQuestion: 60);
        expect(updated.timePerQuestion, 60);
      });

      test('returns new instance with updated questionType', () {
        final updated = base.copyWith(questionType: QuestionType.boolean);
        expect(updated.questionType, QuestionType.boolean);
      });

      test('preserves all fields when no parameters provided', () {
        final copy = base.copyWith();
        expect(copy.numQuestions, base.numQuestions);
        expect(copy.timePerQuestion, base.timePerQuestion);
        expect(copy.questionType, base.questionType);
      });

      test('clearQuestionType sets questionType to null', () {
        final updated = base.copyWith(clearQuestionType: true);
        expect(updated.questionType, isNull);
      });

      test('clearQuestionType preserves numQuestions and timePerQuestion', () {
        final updated = base.copyWith(clearQuestionType: true);
        expect(updated.numQuestions, 10);
        expect(updated.timePerQuestion, 30);
      });

      test('clearQuestionType takes precedence over provided questionType', () {
        // jeśli obie flagi podane jednocześnie, clearQuestionType wygrywa
        final updated = base.copyWith(
          questionType: QuestionType.open6,
          clearQuestionType: true,
        );
        expect(updated.questionType, isNull);
      });

      test('setting questionType to null without flag does not clear it', () {
        // copyWith(questionType: null) bez flagi powinno zachować stary typ
        final updated = base.copyWith();
        expect(updated.questionType, QuestionType.open4);
      });

      test('all three allowed numQuestion values are accepted', () {
        for (final n in [10, 15, 20]) {
          final opts = base.copyWith(numQuestions: n);
          expect(opts.numQuestions, n);
        }
      });
    });
  });
}
*/
