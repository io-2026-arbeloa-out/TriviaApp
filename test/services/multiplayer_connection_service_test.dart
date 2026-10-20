import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';
import 'package:triviaapp/services/multiplayer_connection_service.dart';

class _Sessions extends Fake implements FirebaseSessionRepository {
  String? waitingId = 'room';
  String? privateId;
  int joinCount = 0, createCount = 0, findCount = 0, failures = 0;
  Exception? error;
  int? code;
  @override
  Future<String?> findWaitingSession({required String categoryId, required int maxPlayers}) async {
    findCount++; return waitingId;
  }
  @override
  Future<String?> findPrivateSession({required int entryCode}) async => privateId;
  @override
  Future<String> joinSession({required String sessionId, int? entryCode}) async {
    joinCount++; code = entryCode;
    if (error != null) throw error!;
    if (joinCount <= failures) throw StateError('Session is full');
    return sessionId;
  }
  @override
  Future<String> createSession({required OnlineGameOptions settings}) async {
    createCount++;
    if (error != null) throw error!;
    if (createCount <= failures) throw StateError('Creation failed');
    return 'new';
  }
}

void main() {
  for (final creating in [false, true]) {
    test('retries async ${creating ? 'creation' : 'join'} and searches again', () async {
      final repo = _Sessions()..waitingId = creating ? null : 'room'..failures = 1;
      final result = await MultiplayerConnectionService(sessionRepository: repo).connectPlayer(
        uid: 'user', username: 'User', settings: const OnlineGameOptions(categoryId: 'general'));
      expect(result, creating ? 'new' : 'room'); expect(repo.findCount, 2);
    });
    test('limits async ${creating ? 'creation' : 'join'} retries to three', () async {
      final repo = _Sessions()..waitingId = creating ? null : 'room'..failures = 3;
      await expectLater(MultiplayerConnectionService(sessionRepository: repo).connectPlayer(
        uid: 'user', username: 'User', settings: const OnlineGameOptions(categoryId: 'general')), throwsStateError);
      expect(repo.findCount, 3);
    });
    test('does not retry other ${creating ? 'creation' : 'join'} failures', () async {
      final error = Exception('Denied');
      final repo = _Sessions()..waitingId = creating ? null : 'room'..error = error;
      await expectLater(MultiplayerConnectionService(sessionRepository: repo).connectPlayer(
        uid: 'user', username: 'User', settings: const OnlineGameOptions(categoryId: 'general')), throwsA(same(error)));
      expect(repo.findCount, 1);
    });
  }
  test('private join includes the code and skips public matchmaking', () async {
    final repo = _Sessions()..privateId = 'private-room';
    expect(await MultiplayerConnectionService(sessionRepository: repo).connectPlayer(
      uid: 'user', username: 'User', settings: const OnlineGameOptions(categoryId: 'general', entryCode: 123456)), 'private-room');
    expect(repo.code, 123456); expect(repo.findCount, 0);
  });
}
