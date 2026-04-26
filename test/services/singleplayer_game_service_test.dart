import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';
import 'package:triviaapp/repositories/firebase_rtdb_question_repository.dart';
import 'package:triviaapp/services/singleplayer_game_service.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

class FakeFirebaseRtdbQuestionRepository extends Fake
    implements FirebaseRtdbQuestionRepository {
  List<Question> questionsToReturn = [];
  Exception? error;

  int lastLimit = 0;
  String? lastCategory;
  QuestionType? lastQuestionType;

  @override
  Future<List<Question>> getQuestions({
    required int limit,
    required String category,
    QuestionType? questionType,
  }) async {
    lastLimit = limit;
    lastCategory = category;
    lastQuestionType = questionType;

    if (error != null) throw error!;

    final filtered = questionType == null
        ? questionsToReturn
        : questionsToReturn.where((q) => q.type == questionType).toList();

    return filtered.take(limit).toList();
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Question makeQuestion({
  String id = 'q1',
  String text = 'Pytanie?',
  String category = 'general',
  Set<String> correctAnswers = const {'Poprawna'},
  Set<String> wrongAnswers = const {'Błędna1', 'Błędna2', 'Błędna3'},
  QuestionType type = QuestionType.open4,
}) {
  return Question(
    id: id,
    text: text,
    category: category,
    correctAnswers: correctAnswers,
    wrongAnswers: wrongAnswers,
    type: type,
    difficulty: Difficulty.easy,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeFirebaseRtdbQuestionRepository fakeRepo;
  late SingleplayerGameService service;

  setUp(() {
    fakeRepo = FakeFirebaseRtdbQuestionRepository();
    service = SingleplayerGameService(questionRepository: fakeRepo);
  });

  // ── loadQuestions ──────────────────────────────────────────────────────────

  group('loadQuestions', () {
    test('passes numQuestions as limit to repository', () async {
      const opts =
          SingleplayerGameOptions(numQuestions: 15, timePerQuestion: 30);
      fakeRepo.questionsToReturn =
          List.generate(20, (i) => makeQuestion(id: 'q$i'));

      await service.loadQuestions(opts, 'general');

      expect(fakeRepo.lastLimit, 15);
    });

    test('passes category to repository', () async {
      const opts = SingleplayerGameOptions();
      fakeRepo.questionsToReturn = [makeQuestion(category: 'sports')];

      await service.loadQuestions(opts, 'sports');

      expect(fakeRepo.lastCategory, 'sports');
    });

    test('passes questionType to repository when set', () async {
      const opts = SingleplayerGameOptions(
          questionType: QuestionType.boolean);
      fakeRepo.questionsToReturn = [
        makeQuestion(type: QuestionType.boolean,
            correctAnswers: {'Prawda'}, wrongAnswers: {'Fałsz'})
      ];

      await service.loadQuestions(opts, 'general');

      expect(fakeRepo.lastQuestionType, QuestionType.boolean);
    });

    test('passes null questionType when options have no filter', () async {
      const opts = SingleplayerGameOptions();
      fakeRepo.questionsToReturn = [makeQuestion()];

      await service.loadQuestions(opts, 'general');

      expect(fakeRepo.lastQuestionType, isNull);
    });

    test('returns questions from repository', () async {
      const opts = SingleplayerGameOptions(numQuestions: 2);
      fakeRepo.questionsToReturn = [
        makeQuestion(id: 'q1', text: 'Pytanie 1'),
        makeQuestion(id: 'q2', text: 'Pytanie 2'),
      ];

      final result = await service.loadQuestions(opts, 'general');

      expect(result.length, 2);
    });

    test('returns empty list when repository returns empty', () async {
      const opts = SingleplayerGameOptions();
      fakeRepo.questionsToReturn = [];

      final result = await service.loadQuestions(opts, 'general');

      expect(result, isEmpty);
    });

    test('propagates exception from repository', () async {
      const opts = SingleplayerGameOptions();
      fakeRepo.error = Exception('network error');

      expect(
        () => service.loadQuestions(opts, 'general'),
        throwsException,
      );
    });
  });

  // ── checkAnswer ────────────────────────────────────────────────────────────

  group('checkAnswer', () {
    test('returns true for exact correct answer', () {
      final q = makeQuestion(correctAnswers: {'Warszawa'});
      expect(service.checkAnswer(q, 'Warszawa'), isTrue);
    });

    test('returns false for wrong answer', () {
      final q = makeQuestion(correctAnswers: {'Warszawa'});
      expect(service.checkAnswer(q, 'Kraków'), isFalse);
    });

    test('is case-insensitive', () {
      final q = makeQuestion(correctAnswers: {'Warszawa'});
      expect(service.checkAnswer(q, 'warszawa'), isTrue);
      expect(service.checkAnswer(q, 'WARSZAWA'), isTrue);
      expect(service.checkAnswer(q, 'wArSzAwA'), isTrue);
    });

    test('trims whitespace from player answer', () {
      final q = makeQuestion(correctAnswers: {'Warszawa'});
      expect(service.checkAnswer(q, '  Warszawa  '), isTrue);
    });

    test('trims whitespace from correct answers', () {
      final q = makeQuestion(correctAnswers: {'  Warszawa  '});
      expect(service.checkAnswer(q, 'Warszawa'), isTrue);
    });

    test('returns true when one of multiple correct answers matches', () {
      final q = makeQuestion(correctAnswers: {'1863', 'tysiąc osiemset sześćdziesiąt trzy'});
      expect(service.checkAnswer(q, '1863'), isTrue);
    });

    test('returns false for empty answer', () {
      final q = makeQuestion(correctAnswers: {'Warszawa'});
      expect(service.checkAnswer(q, ''), isFalse);
    });

    test('returns false for whitespace-only answer', () {
      final q = makeQuestion(correctAnswers: {'Warszawa'});
      expect(service.checkAnswer(q, '   '), isFalse);
    });

    test('returns true for boolean question — Prawda', () {
      final q = makeQuestion(
        type: QuestionType.boolean,
        correctAnswers: {'Prawda'},
        wrongAnswers: {'Fałsz'},
      );
      expect(service.checkAnswer(q, 'Prawda'), isTrue);
    });

    test('returns false for boolean question — wrong option selected', () {
      final q = makeQuestion(
        type: QuestionType.boolean,
        correctAnswers: {'Prawda'},
        wrongAnswers: {'Fałsz'},
      );
      expect(service.checkAnswer(q, 'Fałsz'), isFalse);
    });

    test('returns false for answer that is a substring of correct answer', () {
      final q = makeQuestion(correctAnswers: {'Warszawa'});
      expect(service.checkAnswer(q, 'Wars'), isFalse);
    });
  });
}
