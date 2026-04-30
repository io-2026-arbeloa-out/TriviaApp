/*
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/interfaces/i_singleplayer_game_service.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/screens/singleplayer_game_screen.dart';

// ---------------------------------------------------------------------------
// Fake service
// ---------------------------------------------------------------------------

class FakeSingleplayerGameService extends Fake
    implements ISingleplayerGameService {
  List<Question> questionsToReturn = [];
  Exception? loadError;
  bool Function(Question, String)? checkAnswerOverride;

  final Completer<void> _loadCompleter = Completer();

  // Kontroluje kiedy loadQuestions się zakończy — domyślnie od razu.
  bool resolveImmediately = true;

  @override
  Future<List<Question>> loadQuestions(
    SingleplayerGameOptions options,
    String category,
  ) async {
    if (!resolveImmediately) await _loadCompleter.future;
    if (loadError != null) throw loadError!;
    return questionsToReturn;
  }

  void completeLoad() {
    if (!_loadCompleter.isCompleted) _loadCompleter.complete();
  }

  @override
  bool checkAnswer(Question question, String answer) {
    if (checkAnswerOverride != null) {
      return checkAnswerOverride!(question, answer);
    }
    return question.correctAnswers
        .any((c) => c.trim().toLowerCase() == answer.trim().toLowerCase());
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Question makeQuestion({
  String id = 'q1',
  String text = 'Jaka jest stolica Polski?',
  String category = 'general',
  Set<String> correctAnswers = const {'Warszawa'},
  Set<String> wrongAnswers = const {'Kraków', 'Gdańsk', 'Łódź'},
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

Widget buildScreen({
  required FakeSingleplayerGameService service,
  String category = 'general',
  SingleplayerGameOptions gameOptions = const SingleplayerGameOptions(
    timePerQuestion: 0, // brak timera w testach
  ),
}) {
  return MaterialApp(
    home: SingleplayerGameScreen(
      category: category,
      options: UIOptions(),
      gameOptions: gameOptions,
      gameService: service,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeSingleplayerGameService fakeService;

  setUp(() {
    fakeService = FakeSingleplayerGameService();
  });

  // ── Loading phase ──────────────────────────────────────────────────────────

  group('loading phase', () {
    testWidgets('shows CircularProgressIndicator before questions load',
        (tester) async {
      fakeService.resolveImmediately = false;
      fakeService.questionsToReturn = [makeQuestion()];

      await tester.pumpWidget(buildScreen(service: fakeService));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      fakeService.completeLoad();
      await tester.pumpAndSettle();
    });
  });

  // ── Error phase ────────────────────────────────────────────────────────────

  group('error phase', () {
    testWidgets('shows error message when loadQuestions throws', (tester) async {
      fakeService.loadError = Exception('network error');

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Nie udało się załadować pytań.'), findsOneWidget);
    });

    testWidgets('shows error message when questions list is empty',
        (tester) async {
      fakeService.questionsToReturn = [];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Brak pytań dla wybranej kategorii i typu.'),
          findsOneWidget);
    });

    testWidgets('shows Wróć button on error', (tester) async {
      fakeService.loadError = Exception('error');

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Wróć'), findsOneWidget);
    });
  });

  // ── Playing phase ──────────────────────────────────────────────────────────

  group('playing phase', () {
    testWidgets('shows question text', (tester) async {
      fakeService.questionsToReturn = [
        makeQuestion(text: 'Jaka jest stolica Polski?')
      ];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Jaka jest stolica Polski?'), findsOneWidget);
    });

    testWidgets('shows question counter', (tester) async {
      fakeService.questionsToReturn = [makeQuestion()];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Pytanie 1 / 1'), findsOneWidget);
    });

    testWidgets('shows score label', (tester) async {
      fakeService.questionsToReturn = [makeQuestion()];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      expect(find.textContaining('Wynik:'), findsOneWidget);
    });

    testWidgets('shows all answer buttons for open4 question', (tester) async {
      fakeService.questionsToReturn = [
        makeQuestion(
          correctAnswers: {'Warszawa'},
          wrongAnswers: {'Kraków', 'Gdańsk', 'Łódź'},
          type: QuestionType.open4,
        ),
      ];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Warszawa'), findsOneWidget);
      expect(find.text('Kraków'), findsOneWidget);
      expect(find.text('Gdańsk'), findsOneWidget);
      expect(find.text('Łódź'), findsOneWidget);
    });

    testWidgets('shows Prawda and Fałsz for boolean question', (tester) async {
      fakeService.questionsToReturn = [
        makeQuestion(
          type: QuestionType.boolean,
          correctAnswers: {'Prawda'},
          wrongAnswers: {'Fałsz'},
        ),
      ];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Prawda'), findsOneWidget);
      expect(find.text('Fałsz'), findsOneWidget);
    });

    testWidgets('does not show feedback bar before answering', (tester) async {
      fakeService.questionsToReturn = [makeQuestion()];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Poprawna odpowiedź!'), findsNothing);
      expect(find.text('Błędna odpowiedź'), findsNothing);
    });

    testWidgets('does not show timer bar when timePerQuestion is 0',
        (tester) async {
      fakeService.questionsToReturn = [makeQuestion()];

      await tester.pumpWidget(buildScreen(
        service: fakeService,
        gameOptions: const SingleplayerGameOptions(timePerQuestion: 0),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsNothing);
    });

    testWidgets('shows timer bar when timePerQuestion > 0', (tester) async {
      fakeService.questionsToReturn = [makeQuestion()];

      await tester.pumpWidget(buildScreen(
        service: fakeService,
        gameOptions: const SingleplayerGameOptions(timePerQuestion: 30),
      ));
      await tester.pumpAndSettle();

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });
  });

  // ── Feedback phase ─────────────────────────────────────────────────────────

  group('feedback phase', () {
    testWidgets('shows Poprawna odpowiedź after correct answer', (tester) async {
      fakeService.questionsToReturn = [
        makeQuestion(correctAnswers: {'Warszawa'})
      ];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Warszawa'));
      await tester.pumpAndSettle();

      expect(find.text('Poprawna odpowiedź!'), findsOneWidget);
    });

    testWidgets('shows Błędna odpowiedź after wrong answer', (tester) async {
      fakeService.questionsToReturn = [
        makeQuestion(correctAnswers: {'Warszawa'}, wrongAnswers: {'Kraków', 'Gdańsk', 'Łódź'})
      ];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kraków'));
      await tester.pumpAndSettle();

      expect(find.text('Błędna odpowiedź'), findsOneWidget);
    });

    testWidgets('shows correct answer when wrong answer given', (tester) async {
      fakeService.questionsToReturn = [
        makeQuestion(correctAnswers: {'Warszawa'}, wrongAnswers: {'Kraków', 'Gdańsk', 'Łódź'})
      ];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kraków'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Warszawa'), findsWidgets);
    });

    testWidgets('does not show correct answer label on correct answer',
        (tester) async {
      fakeService.questionsToReturn = [
        makeQuestion(correctAnswers: {'Warszawa'})
      ];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Warszawa'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Prawidłowa:'), findsNothing);
    });

    testWidgets('shows Następne button for non-last question', (tester) async {
      fakeService.questionsToReturn = [
        makeQuestion(id: 'q1', text: 'Pytanie 1'),
        makeQuestion(id: 'q2', text: 'Pytanie 2'),
      ];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Warszawa'));
      await tester.pumpAndSettle();

      expect(find.text('Następne'), findsOneWidget);
    });

    testWidgets('shows Wyniki button on last question', (tester) async {
      fakeService.questionsToReturn = [makeQuestion()];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Warszawa'));
      await tester.pumpAndSettle();

      expect(find.text('Wyniki'), findsOneWidget);
    });

    testWidgets('advances to next question after tapping Następne',
        (tester) async {
      fakeService.questionsToReturn = [
        makeQuestion(id: 'q1', text: 'Pytanie pierwsze'),
        makeQuestion(id: 'q2', text: 'Pytanie drugie'),
      ];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Warszawa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Następne'));
      await tester.pumpAndSettle();

      expect(find.text('Pytanie drugie'), findsOneWidget);
      expect(find.text('Pytanie 2 / 2'), findsOneWidget);
    });

    testWidgets('score increments after correct answer', (tester) async {
      fakeService.questionsToReturn = [
        makeQuestion(id: 'q1', correctAnswers: {'Warszawa'}),
        makeQuestion(id: 'q2', text: 'Pytanie 2'),
      ];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Warszawa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Następne'));
      await tester.pumpAndSettle();

      expect(find.text('Wynik: 1'), findsOneWidget);
    });

    testWidgets('score does not increment after wrong answer', (tester) async {
      fakeService.questionsToReturn = [
        makeQuestion(correctAnswers: {'Warszawa'}, wrongAnswers: {'Kraków', 'Gdańsk', 'Łódź'}),
      ];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Kraków'));
      await tester.pumpAndSettle();

      expect(find.text('Wynik: 0'), findsOneWidget);
    });
  });

  // ── Navigation to ScoreTableScreen ─────────────────────────────────────────

  group('navigation to ScoreTableScreen', () {
    testWidgets('navigates to ScoreTableScreen after last question',
        (tester) async {
      fakeService.questionsToReturn = [makeQuestion()];

      await tester.pumpWidget(buildScreen(service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Warszawa'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Wyniki'));
      await tester.pumpAndSettle();

      // ScoreTableScreen pokazuje 'Wyniki gry'
      expect(find.text('Wyniki gry'), findsOneWidget);
    });
  });
}
*/
