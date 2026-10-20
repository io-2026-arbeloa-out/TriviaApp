import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/interfaces/i_singleplayer_game_service.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/game_answer.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';
import 'package:triviaapp/models/singleplayer_session_data.dart';
import 'package:triviaapp/screens/singleplayer_game_screen.dart';

const _question = Question(id: 'q', text: 'Question?', answers: {'A', 'B'}, type: QuestionType.open4, difficulty: Difficulty.easy);
class _Service extends Fake implements ISingleplayerGameService {
  final pending = Completer<GameAnswer>();
  int attempts = 0;
  final submitted = <String>[];
  @override
  Future<List<Question>> loadQuestions(SingleplayerGameOptions options, String category) async => [_question];
  @override
  List<String> getAnswerOptions(Question question) => question.answers.toList();
  @override
  Future<GameAnswer> checkAnswer(Question question, String answer) {
    attempts++; submitted.add(answer);
    return attempts == 1 ? pending.future : Future.value(const GameAnswer(isCorrect: true, correctAnswers: ['A']));
  }
}
Future<SingleplayerSessionData> _start(WidgetTester tester, _Service service) async {
  tester.view.physicalSize = const Size(430, 1000); tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
  final session = SingleplayerSessionData(category: 'general', options: const SingleplayerGameOptions());
  await tester.pumpWidget(MaterialApp(home: SingleplayerGameScreen(sessionData: session, gameService: service)));
  await tester.pumpAndSettle();
  await tester.tap(find.text('A')); await tester.pump();
  return session;
}
void main() {
  testWidgets('waits for server validation and counts exactly once', (tester) async {
    final service = _Service(); final session = await _start(tester, service);
    expect(session.results, isEmpty);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    service.pending.complete(const GameAnswer(isCorrect: true, correctAnswers: ['A']));
    await tester.pumpAndSettle();
    expect(session.results, [true]); expect(service.attempts, 1);
  });
  testWidgets('retries the locked choice without counting failed attempts', (tester) async {
    final service = _Service(); final session = await _start(tester, service);
    service.pending.completeError(Exception('Lost response')); await tester.pumpAndSettle();
    expect(session.results, isEmpty);
    await tester.tap(find.text('Ponów sprawdzenie')); await tester.pumpAndSettle();
    expect(service.submitted, ['A', 'A']); expect(session.results, [true]);
  });
  testWidgets('ignores a server response after leaving', (tester) async {
    final service = _Service(); final session = await _start(tester, service);
    await tester.pumpWidget(const SizedBox());
    service.pending.complete(const GameAnswer(isCorrect: true, correctAnswers: ['A'])); await tester.pump();
    expect(tester.takeException(), isNull); expect(session.results, isEmpty);
  });
}
