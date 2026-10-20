import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/controllers/singleplayer_controller.dart';
import 'package:triviaapp/models/game_answer.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';
import 'package:triviaapp/models/singleplayer_session_data.dart';
import '../support/game_fakes.dart';

const correct = GameAnswer(isCorrect: true, correctAnswers: ['A']);
void main() {
  late SingleplayerServiceFake service;
  late SingleplayerController controller;
  late ManualClock clock;
  bool disposed = false;
  setUp(() {
    disposed = false;
    service = SingleplayerServiceFake();
    clock = ManualClock();
    controller = SingleplayerController(
      service: service,
      schedule: clock.schedule,
      session: SingleplayerSessionData(
        category: 'general',
        options: const SingleplayerGameOptions(timePerQuestion: 3),
      ),
    );
  });
  tearDown(() {
    if (!disposed) controller.dispose();
  });
  test(
    'a double tap submits once and counts only an accepted result',
    () async {
      await controller.load();
      final pending = controller.answer('A');
      await controller.answer('B');
      expect(service.submitted, ['A']);
      expect(controller.answeredQuestions, 0);
      expect(controller.phase, SingleplayerPhase.checking);
      expect(clock.pending, 0);
      service.answers.single.complete(correct);
      await pending;
      expect(controller.answeredQuestions, 1);
      expect(controller.correctAnswers, 1);
      expect(controller.questionState.correctAnswers, ['A']);
    },
  );
  test(
    'retry cannot change the locked choice or duplicate its result',
    () async {
      await controller.load();
      final first = controller.answer('A');
      service.answers.single.completeError(Exception('Lost response'));
      await first;
      await controller.answer('B');
      expect(controller.validationFailed, true);
      final retry = controller.retryAnswer();
      await controller.retryAnswer();
      expect(service.submitted, ['A', 'A']);
      service.answers.last.complete(correct);
      await retry;
      expect(controller.session.results, [true]);
    },
  );
  test(
    'timeout is deterministic and a late timer cannot submit twice',
    () async {
      await controller.load();
      clock.advance(const Duration(seconds: 2));
      expect(service.submitted, isEmpty);
      clock.advance(const Duration(seconds: 1));
      controller.timeOut();
      expect(service.submitted, ['']);
      service.answers.single.complete(
        const GameAnswer(isCorrect: false, correctAnswers: ['A']),
      );
      await pumpEventQueue();
      controller.next();
      controller.next();
      expect(controller.currentIndex, 1);
      expect(controller.phase, SingleplayerPhase.playing);
      clock.advance(const Duration(seconds: 3));
      expect(service.submitted, ['', '']);
      service.answers.last.complete(correct);
      await pumpEventQueue();
    },
  );
  test('completion publishes a finished state without navigation', () async {
    service.loadedQuestions = [gameQuestions().first];
    await controller.load();
    final pending = controller.answer('A');
    service.answers.single.complete(correct);
    await pending;
    controller.next();
    controller.next();
    expect(controller.phase, SingleplayerPhase.finished);
    expect(controller.session.results, [true]);
  });
  test('empty and failed loads publish explicit errors', () async {
    service.loadedQuestions = [];
    await controller.load();
    expect(controller.phase, SingleplayerPhase.error);
    expect(controller.errorMessage, contains('Brak pytań'));
    service.loading = Completer<List<Question>>();
    final load = controller.load();
    service.loading!.completeError(Exception('Unavailable'));
    await load;
    expect(controller.errorMessage, contains('Nie udało się'));
  });
  test('dispose during loading ignores its completion', () async {
    service.loading = Completer<List<Question>>();
    final load = controller.load();
    controller.dispose();
    disposed = true;
    service.loading!.complete(gameQuestions());
    await load;
    expect(controller.questions, isEmpty);
    expect(clock.pending, 0);
  });
  test(
    'dispose during validation cancels timers and ignores the result',
    () async {
      await controller.load();
      final answer = controller.answer('A');
      final session = controller.session;
      controller.dispose();
      disposed = true;
      service.answers.single.complete(correct);
      await answer;
      expect(session.results, isEmpty);
      expect(clock.pending, 0);
    },
  );
}
