import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/interfaces/i_singleplayer_game_service.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';
import 'package:triviaapp/models/singleplayer_session_data.dart';
import 'package:triviaapp/screens/singleplayer_game_screen.dart';

class _PendingGameService extends Fake implements ISingleplayerGameService {
  final questions = Completer<List<Question>>();
  int answerOptionsCalls = 0;

  @override
  Future<List<Question>> loadQuestions(
    SingleplayerGameOptions options,
    String category,
  ) => questions.future;

  @override
  List<String> getAnswerOptions(Question question) {
    answerOptionsCalls++;
    return [...question.answers];
  }
}

const _question = Question(
  id: '0',
  text: 'Question?',
  answers: {'Yes', 'No'},

  type: QuestionType.open4,
  difficulty: Difficulty.easy,
);

Widget _subject(_PendingGameService service) => MaterialApp(
  home: SingleplayerGameScreen(
    sessionData: SingleplayerSessionData(
      category: 'general',
      options: const SingleplayerGameOptions(),
    ),
    gameService: service,
  ),
);

void main() {
  for (final outcome in ['questions', 'empty', 'error']) {
    testWidgets('ignores $outcome after leaving during loading', (
      tester,
    ) async {
      final service = _PendingGameService();
      await tester.pumpWidget(_subject(service));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpWidget(const SizedBox());

      if (outcome == 'error') {
        service.questions.completeError(Exception('Loading failed'));
      } else {
        service.questions.complete(outcome == 'empty' ? [] : [_question]);
      }
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(service.answerOptionsCalls, 0);
    });
  }

  testWidgets('shows the empty result while mounted', (tester) async {
    final service = _PendingGameService();
    await tester.pumpWidget(_subject(service));
    service.questions.complete([]);
    await tester.pump();

    expect(
      find.text('Brak pytań dla wybranej kategorii i typu.'),
      findsOneWidget,
    );
  });

  testWidgets('shows a loading error while mounted', (tester) async {
    final service = _PendingGameService();
    await tester.pumpWidget(_subject(service));
    service.questions.completeError(Exception('Loading failed'));
    await tester.pump();

    expect(find.text('Nie udało się załadować pytań.'), findsOneWidget);
  });
}
