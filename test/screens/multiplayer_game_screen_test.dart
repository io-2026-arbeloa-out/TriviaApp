import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/models/game_answer.dart';
import 'package:triviaapp/models/game_route_arguments.dart';
import 'package:triviaapp/screens/multiplayer_game_screen.dart';
import '../support/game_fakes.dart';
import '../support/session_fixtures.dart';

void main() {
  late MultiplayerServiceFake service;
  setUp(() => service = MultiplayerServiceFake());
  tearDown(() => service.updates.close());

  Future<void> openGame(WidgetTester tester) async {
    service.latest = sessionSnapshot().forPlayer('uid1');
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppRoute.instance.navigatorKey,
        home: MultiplayerGameScreen(gameService: service),
        routes: {
          AppRoute.multiplayerScoreTableScreen: (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as MultiplayerScoreArguments;
            expect(args.myUid, 'uid1');
            expect(args.session.sessionId, 'room');
            return const Scaffold(body: Text('Results'));
          },
        },
      ),
    );
    await tester.pump();
  }

  testWidgets('answer taps are locked until server feedback', (tester) async {
    await openGame(tester);
    await tester.tap(find.text('A'));
    await tester.tap(find.text('B'));
    await tester.pump();
    expect(service.submitted.length, 1);
    service.answers.single.complete(
      const GameAnswer(isCorrect: true, correctAnswers: ['A']),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'late failure does not replace the next question or show a stale retry',
    (tester) async {
      await openGame(tester);
      await tester.tap(find.text('A'));
      service.emit(sessionSnapshot(index: 1).forPlayer('uid1'));
      await tester.pump();
      service.answers.single.completeError(Exception('Old answer failed'));
      await tester.pump();
      expect(find.text('Question 1?'), findsOneWidget);
      expect(find.textContaining('Błąd wysyłania'), findsNothing);
      await tester.tap(find.text('B'));
      expect(service.submitted.length, 2);
      service.answers.last.complete(
        const GameAnswer(isCorrect: false, correctAnswers: ['A']),
      );
      await tester.pump();
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('only ready results trigger navigation with typed arguments', (
    tester,
  ) async {
    await openGame(tester);
    service.emit(
      sessionSnapshot(status: 'finished', phase: 'finished').forPlayer('uid1'),
    );
    await tester.pump();
    expect(service.archiveCalls, 0);
    expect(find.text('Results'), findsNothing);
    service.emit(
      sessionSnapshot(
        status: 'finished',
        phase: 'finished',
        ready: true,
      ).forPlayer('uid1'),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Results'), findsOneWidget);
    expect(service.archiveCalls, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
