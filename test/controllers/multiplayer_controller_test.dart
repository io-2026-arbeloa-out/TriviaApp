import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/controllers/multiplayer_controller.dart';
import 'package:triviaapp/models/game_answer.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/session_snapshot.dart';
import '../support/game_fakes.dart';
import '../support/session_fixtures.dart';

void main() {
  late MultiplayerServiceFake service;
  late MultiplayerController controller;
  late ManualClock clock;
  bool disposed = false;
  setUp(() {
    disposed = false;
    service = MultiplayerServiceFake();
    clock = ManualClock();
    controller = MultiplayerController(
      service: service,
      schedule: clock.schedule,
    );
  });
  tearDown(() async {
    if (!disposed) controller.dispose();
    await service.updates.close();
  });
  Future<void> emit({
    int index = 0,
    String phase = 'answering',
    String status = 'inProgress',
    bool ready = false,
  }) async {
    service.emit(
      sessionSnapshot(
        index: index,
        phase: phase,
        status: status,
        ready: ready,
      ).forPlayer('uid1'),
    );
    await pumpEventQueue();
  }

  test(
    'no events produces a retryable connection error; a subsequent snapshot recovers',
    () async {
      await controller.connect();
      clock.advance(const Duration(seconds: 12));
      expect(controller.connectionError, isNotNull);
      expect(controller.phase, MultiplayerPhase.loading);
      await emit();
      expect(controller.connectionError, isNull);
      expect(controller.phase, MultiplayerPhase.answering);
    },
  );
  test(
    'double taps are locked and only the server reveals correctness',
    () async {
      await controller.connect();
      await emit();
      final pending = controller.answer('A');
      await controller.answer('B');
      expect(service.submitted.length, 1);
      expect(controller.isAnswerCorrect, isNull);
      service.answers.single.complete(
        const GameAnswer(isCorrect: true, correctAnswers: ['A']),
      );
      await pending;
      expect(controller.isAnswerCorrect, true);
      expect(controller.revealedAnswers, ['A']);
    },
  );
  test(
    'late failure from the previous round cannot lock or reset a new round',
    () async {
      await controller.connect();
      await emit();
      final oldAnswer = controller.answer('A');
      await emit(index: 1);
      service.answers.first.completeError(Exception('Delayed'));
      await oldAnswer;
      expect(controller.phase, MultiplayerPhase.answering);
      expect(controller.answerError, isNull);
      expect(controller.hasAnswered, false);
      expect(controller.selectedAnswer, isNull);
    },
  );
  test(
    'reconnect retains a locked answer and retries the exact same choice',
    () async {
      await controller.connect();
      await emit();
      final answer = controller.answer('A');
      service.answers.single.completeError(Exception('Lost response'));
      await answer;
      service.updates.addError(Exception('Disconnected'));
      await pumpEventQueue();
      await controller.connect();
      await pumpEventQueue();
      expect(service.connections, 2);
      expect(controller.selectedAnswer, 'A');
      expect(controller.hasAnswered, true);
      expect(controller.connectionError, isNull);
      final retry = controller.retryAnswer(expectedRoundIndex: 0);
      expect(service.submitted.last.answer, 'A');
      service.answers.last.complete(
        const GameAnswer(isCorrect: true, correctAnswers: ['A']),
      );
      await retry;
    },
  );
  test(
    'a retry action from an older round cannot retry a different choice',
    () async {
      await controller.connect();
      await emit();
      final first = controller.answer('A');
      service.answers.single.completeError(Exception('Lost'));
      await first;
      await emit(index: 1);
      final second = controller.answer('B');
      service.answers.last.completeError(Exception('Lost again'));
      await second;
      await controller.retryAnswer(expectedRoundIndex: 0);
      expect(service.submitted.length, 2);
    },
  );
  test('eliminated players cannot submit', () async {
    final data = sessionDocument();
    data['players']['uid1']['isEliminated'] = true;
    await controller.connect();
    service.emit(SessionSnapshot.fromJson('room', data).forPlayer('uid1'));
    await pumpEventQueue();
    await controller.answer('A');
    expect(controller.phase, MultiplayerPhase.eliminated);
    expect(service.submitted, isEmpty);
  });
  test('a resolving round without further events reports a stall', () async {
    await controller.connect();
    await emit(phase: 'resolving');
    clock.advance(const Duration(seconds: 12));
    expect(controller.roundStalled, true);
    await emit(index: 1);
    expect(controller.roundStalled, false);
  });
  test(
    'results are fetched once only after readiness and retries are deterministic',
    () async {
      var failures = 0;
      service.readArchive = () async {
        if (failures++ < 2) throw Exception('Not available');
        return MultiplayerSessionData.fromJson(archiveDocument());
      };
      await controller.connect();
      await emit(status: 'finished', phase: 'finished');
      expect(service.archiveCalls, 0);
      await emit(status: 'finished', phase: 'finished', ready: true);
      expect(service.archiveCalls, 1);
      clock.advance(const Duration(seconds: 2));
      await pumpEventQueue();
      clock.advance(const Duration(seconds: 2));
      await pumpEventQueue();
      expect(service.archiveCalls, 3);
      expect(controller.finalSession, isNotNull);
      expect(controller.resultsError, isNull);
    },
  );
  test(
    'repeated resolving snapshots do not postpone the stall deadline',
    () async {
      await controller.connect();
      await emit(phase: 'resolving');
      clock.advance(const Duration(seconds: 6));
      await emit(phase: 'resolving');
      clock.advance(const Duration(seconds: 6));
      expect(controller.roundStalled, true);
    },
  );

  test('archive failures stop after five attempts', () async {
    service.readArchive = () async => throw StateError('Unavailable');
    await controller.connect();
    await emit(status: 'finished', phase: 'finished', ready: true);
    for (var i = 0; i < 4; i++) {
      clock.advance(const Duration(seconds: 2));
      await pumpEventQueue();
    }
    expect(service.archiveCalls, 5);
    expect(controller.resultsError, isStateError);
    expect(controller.finalSession, isNull);
    expect(clock.pending, 0);
  });

  test(
    'dispose cancels archive retries and ignores a pending answer failure',
    () async {
      service.readArchive = () async => throw StateError('Unavailable');
      await controller.connect();
      await emit();
      final pending = controller.answer('A');
      await emit(status: 'finished', phase: 'finished', ready: true);
      controller.dispose();
      disposed = true;
      service.answers.single.completeError(StateError('Late'));
      await pending;
      clock.advance(const Duration(seconds: 10));
      expect(service.archiveCalls, 1);
      expect(controller.answerError, isNull);
      expect(clock.pending, 0);
    },
  );
  test(
    'leaving cancels pending operations without letting their error change state',
    () async {
      await controller.connect();
      await emit();
      final answer = controller.answer('A');
      await controller.leave();
      await controller.leave();
      service.answers.single.completeError(Exception('Late'));
      await answer;
      expect(service.leaveCalls, 1);
      expect(controller.answerError, isNull);
      expect(clock.pending, 0);
    },
  );
  test('dispose during archive loading ignores completion', () async {
    final pending = Completer<MultiplayerSessionData>();
    service.readArchive = () => pending.future;
    await controller.connect();
    await emit(status: 'finished', phase: 'finished', ready: true);
    controller.dispose();
    disposed = true;
    pending.complete(MultiplayerSessionData.fromJson(archiveDocument()));
    await pumpEventQueue();
    expect(controller.finalSession, isNull);
    expect(clock.pending, 0);
  });
}
