import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:triviaapp/models/player.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/session_data.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';
import 'package:triviaapp/services/multiplayer_connection_service.dart';
import 'package:triviaapp/services/multiplayer_game_service.dart';

class MockFirebaseSessionRepository extends Mock implements FirebaseSessionRepository {}
class MockFirebaseQuestionRepository extends Mock implements FirebaseQuestionRepository {}
class FakeQuestion extends Fake implements Question {}
class FakePlayer extends Fake implements Player {}
class FakeSessionData extends Fake implements SessionData {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeQuestion());
    registerFallbackValue(FakePlayer());
    registerFallbackValue(FakeSessionData());
  });

  test('MultiplayerConnectionService tworzy sesję rankingową', () async {
    final repo = MockFirebaseSessionRepository();
    final service = MultiplayerConnectionService(repo);
    final session = FakeSessionData();

    when(() => repo.createMultiplayerSession(any(), any()))
        .thenAnswer((_) async => session);

    final result = await service.connectPlayer();

    expect(result, same(session));
    verify(() => repo.createMultiplayerSession(any(), any())).called(1);
  });

  test('MultiplayerGameService nasłuchuje zmian sesji', () async {
    final sessionRepo = MockFirebaseSessionRepository();
    final questionRepo = MockFirebaseQuestionRepository();
    final service = MultiplayerGameService(sessionRepo, questionRepo);

    when(() => sessionRepo.getSessionStream('session-1'))
        .thenAnswer((_) => const Stream.empty());

    expect(service.listenToSession('session-1'), emitsDone);
  });

  test('listenToSession emituje dane sesji', () {
    final sessionRepo = MockFirebaseSessionRepository();
    final service = MultiplayerGameService(sessionRepo, questionRepo);
    final sessionData = SessionData(id: 'session-1', players: []);

    when(() => sessionRepo.getSessionStream('session-1'))
        .thenAnswer((_) => Stream.value(sessionData));

    expect(
        service.listenToSession('session-1'),
        emits(sessionData)
    );
  });
