import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

// ── Fakes ─────────────────────────────────────────────────────────────────────

class _FakeProfileRepo extends Fake implements FirebaseProfileRepository {
  ProfileData? profileToReturn;

  @override
  Future<ProfileData> getProfileData() async {
    if (profileToReturn == null) {
      throw Exception('Profile not found');
    }
    return profileToReturn!;
  }
}

// ── Seed helpers ──────────────────────────────────────────────────────────────

/// Inserts a minimal waiting session directly into [fakeFirestore].
/// Returns the new document ID.
Future<String> _seedSession(
    FakeFirebaseFirestore fakeFirestore, {
      String categoryId = 'general',
      int maxPlayers = 2,
      bool isPrivate = false,
      int? entryCode,
      List<String> playerUids = const ['host'],
    }) async {
  final doc = fakeFirestore.collection('sessions').doc();
  final playersMap = {
    for (final uid in playerUids)
      uid: {
        'username': uid,
        'isEliminated': false,
        'profilePicture': 'avatar.png',
        'lotteryTickets': 0,
        'correctAnswers': 0,
        'totalAnswers': 0,
      }
  };
  await doc.set({
    'status': 'waiting',
    'phase': 'answering',
    'categoryId': categoryId,
    'maxPlayers': maxPlayers,
    'questionTimeLimit': 30,
    'isPrivate': isPrivate,
    'entryCode': entryCode,
    'questionIds': ['q0', 'q1', 'q2'],
    'playerUids': playerUids,
    'activePlayerCount': playerUids.length,
    'currentQuestionIndex': 0,
    'players': playersMap,
    'lastRoundResult': null,
    'rounds': [],
    'createdAt': null,
    'gameStartTime': null,
    'endTime': null,
  });
  return doc.id;
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirebaseSessionRepository repo;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    repo = FirebaseSessionRepository(
      firestore: fakeFirestore,
      profileRepo: _FakeProfileRepo(),
    );
  });

  // ── findWaitingSession ─────────────────────────────────────────────────────

  group('findWaitingSession', () {
    test('returns the ID of a matching public waiting session', () async {
      final id = await _seedSession(fakeFirestore, categoryId: 'general', maxPlayers: 2);
      expect(await repo.findWaitingSession(categoryId: 'general', maxPlayers: 2), id);
    });

    test('returns null when category does not match', () async {
      await _seedSession(fakeFirestore, categoryId: 'sports', maxPlayers: 2);
      expect(await repo.findWaitingSession(categoryId: 'general', maxPlayers: 2), isNull);
    });

    test('returns null when maxPlayers does not match', () async {
      await _seedSession(fakeFirestore, categoryId: 'general', maxPlayers: 4);
      expect(await repo.findWaitingSession(categoryId: 'general', maxPlayers: 2), isNull);
    });

    test('skips private sessions', () async {
      await _seedSession(
        fakeFirestore,
        categoryId: 'general',
        maxPlayers: 2,
        isPrivate: true,
        entryCode: 111111,
      );
      expect(await repo.findWaitingSession(categoryId: 'general', maxPlayers: 2), isNull);
    });

    test('returns null when no sessions exist', () async {
      expect(await repo.findWaitingSession(categoryId: 'general', maxPlayers: 2), isNull);
    });
  });

  // ── findPrivateSession ─────────────────────────────────────────────────────

  group('findPrivateSession', () {
    test('returns the ID of the session with the matching entry code', () async {
      final id = await _seedSession(fakeFirestore, isPrivate: true, entryCode: 654321);
      expect(await repo.findPrivateSession(entryCode: 654321), id);
    });

    test('returns null when entry code does not match', () async {
      await _seedSession(fakeFirestore, isPrivate: true, entryCode: 111111);
      expect(await repo.findPrivateSession(entryCode: 999999), isNull);
    });

    test('returns null when no sessions exist', () async {
      expect(await repo.findPrivateSession(entryCode: 123456), isNull);
    });
  });

  // ── createSession ──────────────────────────────────────────────────────────

  group('createSession', () {
    test('persists correct fields for a private session', () async {
      const settings = OnlineGameOptions(
        categoryId: 'history',
        maxPlayers: 4,
        questionTimeLimit: 20,
        entryCode: 123456,
      );

      final id = await repo.createSession(
        settings: settings,
        questionIds: ['q1', 'q2', 'q3'],
        uid: 'u1',
        username: 'Alice',
      );

      final data = (await fakeFirestore.collection('sessions').doc(id).get()).data()!;
      expect(data['status'], 'waiting');
      expect(data['categoryId'], 'history');
      expect(data['maxPlayers'], 4);
      expect(data['questionTimeLimit'], 20);
      expect(data['isPrivate'], isTrue);
      expect(data['entryCode'], 123456);
      expect(data['questionIds'], ['q1', 'q2', 'q3']);
      expect(data['playerUids'], ['u1']);
      expect(data['activePlayerCount'], 1);
    });

    test('sets isPrivate to false for a public session', () async {
      const settings = OnlineGameOptions(categoryId: 'general', maxPlayers: 2);

      final id = await repo.createSession(
        settings: settings,
        questionIds: ['q1'],
        uid: 'u1',
        username: 'Alice',
      );

      final data = (await fakeFirestore.collection('sessions').doc(id).get()).data()!;
      expect(data['isPrivate'], isFalse);
      expect(data['entryCode'], isNull);
    });

    test('initialises the host player entry', () async {
      const settings = OnlineGameOptions(categoryId: 'general', maxPlayers: 2);

      final id = await repo.createSession(
        settings: settings,
        questionIds: ['q1'],
        uid: 'u1',
        username: 'Alice',
      );

      final data = (await fakeFirestore.collection('sessions').doc(id).get()).data()!;
      final players = data['players'] as Map<String, dynamic>;
      expect(players.containsKey('u1'), isTrue);
      expect(players['u1']['username'], 'Alice');
      expect(players['u1']['isEliminated'], isFalse);
      expect(players['u1']['lotteryTickets'], 0);
    });
  });

  // ── joinSession ────────────────────────────────────────────────────────────

  group('joinSession', () {
    test('adds the second player to the session', () async {
      final id = await _seedSession(fakeFirestore, maxPlayers: 3);

      await repo.joinSession(sessionId: id, uid: 'u2', username: 'Bob');

      final data = (await fakeFirestore.collection('sessions').doc(id).get()).data()!;
      expect(data['playerUids'], containsAll(['host', 'u2']));
      expect(data['activePlayerCount'], 2);
      expect((data['players'] as Map).containsKey('u2'), isTrue);
    });

    test('auto-starts a public session when it reaches maxPlayers', () async {
      // maxPlayers=2, 'host' is already in the session
      final id = await _seedSession(fakeFirestore, maxPlayers: 2);

      await repo.joinSession(sessionId: id, uid: 'u2', username: 'Bob');

      final data = (await fakeFirestore.collection('sessions').doc(id).get()).data()!;
      expect(data['status'], 'inProgress');
      expect(data['gameStartTime'], isNotNull);

      final counter = await fakeFirestore
          .collection('sessions')
          .doc(id)
          .collection('roundCounters')
          .doc('0')
          .get();
      expect(counter.exists, isTrue);
      expect(counter.data()!['targetCount'], 2);
      expect(counter.data()!['resolved'], isFalse);
    });

    test('does NOT auto-start a private session when full', () async {
      final id = await _seedSession(
        fakeFirestore,
        maxPlayers: 2,
        isPrivate: true,
        entryCode: 111111,
      );

      await repo.joinSession(sessionId: id, uid: 'u2', username: 'Bob');

      final data = (await fakeFirestore.collection('sessions').doc(id).get()).data()!;
      expect(data['status'], 'waiting');
    });

    test('throws StateError when session is full', () async {
      // maxPlayers=1, host is already in — no room left
      final id = await _seedSession(fakeFirestore, maxPlayers: 1);

      await expectLater(
        repo.joinSession(sessionId: id, uid: 'u2', username: 'Bob'),
        throwsA(isA<StateError>().having((e) => e.message, 'message', contains('full'))),
      );
    });

    test('is idempotent when the same player joins twice', () async {
      final id = await _seedSession(fakeFirestore, maxPlayers: 3);

      // 'host' is already in the session — joining again should be a no-op
      await repo.joinSession(sessionId: id, uid: 'host', username: 'Host');

      final data = (await fakeFirestore.collection('sessions').doc(id).get()).data()!;
      expect((data['playerUids'] as List).length, 1);
    });

    test('throws StateError when session is no longer in waiting status', () async {
      final id = await _seedSession(fakeFirestore, maxPlayers: 3);
      await fakeFirestore
          .collection('sessions')
          .doc(id)
          .update({'status': 'inProgress'});

      await expectLater(
        repo.joinSession(sessionId: id, uid: 'u2', username: 'Bob'),
        throwsA(isA<StateError>()),
      );
    });
  });

  // ── startSession ───────────────────────────────────────────────────────────

  group('startSession', () {
    test('transitions status to inProgress and creates roundCounters/0', () async {
      final id = await _seedSession(
        fakeFirestore,
        maxPlayers: 4,
        isPrivate: true,
        entryCode: 999999,
        playerUids: ['host', 'u2'],
      );

      await repo.startSession(sessionId: id);

      final data = (await fakeFirestore.collection('sessions').doc(id).get()).data()!;
      expect(data['status'], 'inProgress');
      expect(data['gameStartTime'], isNotNull);

      final counter = await fakeFirestore
          .collection('sessions')
          .doc(id)
          .collection('roundCounters')
          .doc('0')
          .get();
      expect(counter.exists, isTrue);
      expect(counter.data()!['targetCount'], 2);
      expect(counter.data()!['resolved'], isFalse);
    });

    test('is a no-op when status is already inProgress', () async {
      final id = await _seedSession(fakeFirestore);
      await fakeFirestore.collection('sessions').doc(id).update({'status': 'inProgress'});

      await repo.startSession(sessionId: id); // must not throw

      final data = (await fakeFirestore.collection('sessions').doc(id).get()).data()!;
      expect(data['status'], 'inProgress');
    });
  });

  // ── removePlayer ───────────────────────────────────────────────────────────

  group('removePlayer', () {
    test('removes a player while keeping the session alive', () async {
      final id = await _seedSession(
        fakeFirestore,
        maxPlayers: 3,
        playerUids: ['host', 'u2'],
      );

      await repo.removePlayer(sessionId: id, uid: 'u2');

      final data = (await fakeFirestore.collection('sessions').doc(id).get()).data()!;
      expect(data['playerUids'], isNot(contains('u2')));
      expect(data['activePlayerCount'], 1);
    });

    test('deletes the session when the last player leaves', () async {
      final id = await _seedSession(fakeFirestore, playerUids: ['host']);

      await repo.removePlayer(sessionId: id, uid: 'host');

      final snap = await fakeFirestore.collection('sessions').doc(id).get();
      expect(snap.exists, isFalse);
    });

    test('does nothing when session status is not waiting', () async {
      final id = await _seedSession(fakeFirestore, playerUids: ['host']);
      await fakeFirestore.collection('sessions').doc(id).update({'status': 'inProgress'});

      await repo.removePlayer(sessionId: id, uid: 'host');

      // Session must still exist
      expect((await fakeFirestore.collection('sessions').doc(id).get()).exists, isTrue);
    });
  });

  // ── updateSessionSettings ──────────────────────────────────────────────────

  group('updateSessionSettings', () {
    test('updates all mutable lobby fields', () async {
      final id = await _seedSession(fakeFirestore);

      await repo.updateSessionSettings(
        sessionId: id,
        questionTimeLimit: 60,
        maxPlayers: 8,
        categoryId: 'science',
      );

      final data = (await fakeFirestore.collection('sessions').doc(id).get()).data()!;
      expect(data['questionTimeLimit'], 60);
      expect(data['maxPlayers'], 8);
      expect(data['categoryId'], 'science');
    });
  });

  // ── submitAnswer ───────────────────────────────────────────────────────────

  group('submitAnswer', () {
    test('creates a document in the answers subcollection', () async {
      final id = await _seedSession(fakeFirestore);

      await repo.submitAnswer(
        sessionId: id,
        uid: 'host',
        roundIndex: 0,
        questionId: 'q0',
        answer: '1863',
      );

      final doc = await fakeFirestore
          .collection('sessions')
          .doc(id)
          .collection('answers')
          .doc('host_0')
          .get();

      expect(doc.exists, isTrue);
      expect(doc.data()!['answer'], '1863');
      expect(doc.data()!['questionId'], 'q0');
      expect(doc.data()!['roundIndex'], 0);
      expect(doc.data()!['uid'], 'host');
    });

    test('overwrites a previous answer for the same uid and round', () async {
      final id = await _seedSession(fakeFirestore);

      await repo.submitAnswer(
        sessionId: id,
        uid: 'host',
        roundIndex: 0,
        questionId: 'q0',
        answer: 'first',
      );
      await repo.submitAnswer(
        sessionId: id,
        uid: 'host',
        roundIndex: 0,
        questionId: 'q0',
        answer: 'second',
      );

      final doc = await fakeFirestore
          .collection('sessions')
          .doc(id)
          .collection('answers')
          .doc('host_0')
          .get();
      expect(doc.data()!['answer'], 'second');
    });
  });
}