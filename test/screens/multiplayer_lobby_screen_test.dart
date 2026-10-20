import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/app_dependencies.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/interfaces/i_multiplayer_connection_service.dart';
import 'package:triviaapp/models/game_route_arguments.dart';
import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/models/session_snapshot.dart';
import 'package:triviaapp/repositories/session_repository.dart';
import 'package:triviaapp/screens/multiplayer_lobby_screen.dart';
import '../support/game_fakes.dart';
import '../support/session_fixtures.dart';

class _Sessions extends Fake implements SessionRepository {
  final updates = StreamController<SessionSnapshot>.broadcast();
  @override
  Stream<SessionSnapshot> sessionDocStream(String sessionId) => updates.stream;
}

class _Connection extends Fake implements IMultiplayerConnectionService {
  int disconnects = 0;
  Completer<String>? pending;
  @override
  Future<String> connectPlayer({
    required String uid,
    required String username,
    required OnlineGameOptions settings,
  }) async => pending == null ? 'room123' : await pending!.future;
  @override
  Future<void> disconnectPlayer({
    required String sessionId,
    required String uid,
  }) async {
    expect(sessionId, 'room123');
    expect(uid, 'uid1');
    disconnects++;
  }
}

void main() {
  late _Sessions sessions;
  late _Connection connection;
  late MultiplayerServiceFake game;
  setUp(() {
    sessions = _Sessions();
    connection = _Connection();
    game = MultiplayerServiceFake();
  });
  tearDown(() async {
    await sessions.updates.close();
    await game.updates.close();
  });

  Future<void> openLobby(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: AppRoute.instance.navigatorKey,
        initialRoute: '/lobby',
        routes: {
          '/': (_) => const Scaffold(body: Text('Menu')),
          '/lobby': (_) => MultiplayerLobbyScreen(
            dependencies: AppDependencies(sessionRepository: sessions),
            uid: 'uid1',
            username: 'Player',
            settings: const OnlineGameOptions(categoryId: 'general'),
            connectionService: connection,
            gameService: game,
          ),
          AppRoute.multiplayerGameScreen: (context) {
            final args =
                ModalRoute.of(context)!.settings.arguments
                    as MultiplayerGameArguments;
            expect(args.gameService, same(game));
            return const Scaffold(body: Text('Game'));
          },
        },
      ),
    );
    await tester.pump();
  }

  testWidgets(
    'starting a game disposes the lobby without leaving the session',
    (tester) async {
      await openLobby(tester);
      expect(find.text('Oczekiwanie na graczy'), findsOneWidget);
      sessions.updates.add(sessionSnapshot());
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Game'), findsOneWidget);
      expect(find.byType(MultiplayerLobbyScreen), findsNothing);
      expect(connection.disconnects, 0);
    },
  );

  testWidgets(
    'explicit departure leaves exactly once including route disposal',
    (tester) async {
      await openLobby(tester);
      await tester.tap(find.text('Opuść lobby'));
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('Menu'), findsOneWidget);
      expect(connection.disconnects, 1);
    },
  );

  testWidgets('removing a waiting lobby releases its membership', (
    tester,
  ) async {
    await openLobby(tester);
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(connection.disconnects, 1);
  });

  testWidgets(
    'a connection completing after disposal releases its membership',
    (tester) async {
      connection.pending = Completer<String>();
      await openLobby(tester);
      await tester.pumpWidget(const SizedBox());
      connection.pending!.complete('room123');
      await tester.pump();
      expect(connection.disconnects, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
