import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/repositories/firebase_game_commands.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

class _Commands extends Fake implements FirebaseGameCommands {
  String? name;
  Map<String, dynamic>? data;
  Map<String, dynamic> result = {'sessionId': 'server-id'};
  @override
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data) async {
    this.name = name; this.data = data; return result;
  }
}

void main() {
  late FakeFirebaseFirestore db;
  late _Commands commands;
  late FirebaseSessionRepository repo;
  setUp(() {
    db = FakeFirebaseFirestore(); commands = _Commands();
    repo = FirebaseSessionRepository(firestore: db, commands: commands);
  });
  test('matchmaking excludes private lobbies before querying', () async {
    for (final private in [true, false]) {
      await db.collection('sessions').doc(private ? 'private' : 'public').set({
        'status': 'waiting', 'categoryId': 'general', 'maxPlayers': 2, 'isPrivate': private,
      });
    }
    expect(await repo.findWaitingSession(categoryId: 'general', maxPlayers: 2), 'public');
    expect(await repo.findWaitingSession(categoryId: 'missing', maxPlayers: 2), isNull);
  });
  test('private lookup sends only the supplied code to the server', () async {
    expect(await repo.findPrivateSession(entryCode: 123456), 'server-id');
    expect(commands.name, 'findPrivateSession'); expect(commands.data, {'entryCode': 123456});
    commands.result = {'sessionId': null};
    expect(await repo.findPrivateSession(entryCode: 123456), isNull);
  });
  test('creation never sends player identity, score or a client-selected pool', () async {
    expect(await repo.createSession(settings: const OnlineGameOptions(categoryId: 'general')), 'server-id');
    expect(commands.data!.keys.toSet(), {'categoryId', 'maxPlayers', 'questionTimeLimit', 'difficulty', 'entryCode'});
    expect((await db.collection('sessions').get()).docs, isEmpty);
  });
  test('join forwards the entry code without client identity', () async {
    await repo.joinSession(sessionId: 'room', entryCode: 123456);
    expect(commands.data, {'sessionId': 'room', 'entryCode': 123456});
  });
  test('leave identity is never taken from the UI argument', () async {
    await repo.leaveGame(sessionId: 'room', uid: 'forged-other-player');
    expect(commands.name, 'leaveSession'); expect(commands.data, {'sessionId': 'room'});
  });
  test('answer forwards no claimed correctness and returns server feedback', () async {
    commands.result = {'isCorrect': true, 'correctAnswers': ['A']};
    final result = await repo.submitAnswer(sessionId: 'room', uid: 'forged', roundIndex: 0, questionId: 'q', answer: 'A');
    expect(commands.data, {'sessionId': 'room', 'roundIndex': 0, 'questionId': 'q', 'answer': 'A'});
    expect(result.isCorrect, isTrue); expect(result.correctAnswers, ['A']);
  });
  test('session streams still read server documents', () async {
    await db.collection('sessions').doc('room').set({'status': 'waiting'});
    expect(await repo.sessionDocStream('room').first, {'status': 'waiting'});
  });
}
