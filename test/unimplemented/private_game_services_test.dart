/*
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';
import 'package:triviaapp/services/private_game_creation_service.dart';
import 'package:triviaapp/services/private_game_join_service.dart';

class MockFirebaseSessionRepository extends Mock implements FirebaseSessionRepository {}
class FakeSessionData extends Fake implements SessionData {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeSessionData());
  });

  test('PrivateGameCreationService tworzy prywatną sesję', () async {
    final repo = MockFirebaseSessionRepository();
    final service = PrivateGameCreationService(repo);
    final session = FakeSessionData();

    when(() => repo.createMultiplayerSession(any(), any()))
        .thenAnswer((_) async => session);

    final result = await service.createPrivateGame({'category_id': 'general'});

    expect(result, same(session));
  });

  test('PrivateGameJoinService dołącza do pokoju po kodzie', () async {
    final repo = MockFirebaseSessionRepository();
    final service = PrivateGameJoinService(repo);
    final session = FakeSessionData();

    when(() => repo.joinMultiplayerSession(any(), any()))
        .thenAnswer((_) async => session);

    final result = await service.joinPrivateGame(123456);

    expect(result, same(session));
    verify(() => repo.joinMultiplayerSession(any(), any())).called(1);
  });

  test('PrivateGameJoinService nasłuchuje lobby', () async {
    final repo = MockFirebaseSessionRepository();
    final service = PrivateGameJoinService(repo);

    when(() => repo.getSessionStream('session-1'))
        .thenAnswer((_) => const Stream.empty());

    expect(service.listenToLobby('session-1'), emitsDone);
  });
}
*/
void main() {}