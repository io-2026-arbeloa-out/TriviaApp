import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:triviaapp/models/live_game_state.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/session_status.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';
import 'package:triviaapp/services/multiplayer_game_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockUser extends Mock implements User {}
class MockQuestionRepository extends Mock implements FirebaseQuestionRepository {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _sessionId = 'sess1';
const _myUid = 'uid1';
const _myUsername = 'TestUser';
const _categoryId = 'general';

Question _makeQuestion(String id) => Question.fromJson({
      'id': id,
      'category': _categoryId,
      'text': 'Question $id',
      'correctAnswers': ['CorrectAnswer'],
      'wrongAnswers': ['Wrong1', 'Wrong2', 'Wrong3'],
      'difficulty': 'easy',
      'type': 'open4',
    });

/// Minimalne dane dokumentu sesji w stanie 'answering'.
Map<String, dynamic> _answeringSessionDoc({
  int questionIndex = 0,
  Map<String, dynamic>? players,
}) =>
    {
      'questionIds': ['0', '1', '2'],
      'categoryId': _categoryId,
      'status': 'inProgress',
      'phase': 'answering',
      'currentQuestionIndex': questionIndex,
      'players': players ??
          {
            _myUid: {
              'username': _myUsername,
              'profilePicture': 'avatar.png',
              'isEliminated': false,
              'lotteryTickets': 0,
            }
          },
      'lastRoundResult': null,
    };

// ---------------------------------------------------------------------------
// Test setup factory
// ---------------------------------------------------------------------------

/// Tworzy FakeFirestore z użytkownikiem i sesją, tworzy serwis i czeka na
/// zakończenie inicjalizacji. Zwraca gotowy serwis oraz fake Firestore
/// (do manipulowania dokumentami w testach strumienia).
Future<({MultiplayerGameService service, FakeFirebaseFirestore firestore})>
    _createService({
  MockQuestionRepository? questionRepo,
  Map<String, dynamic>? sessionDoc,
}) async {
  final fakeFirestore = FakeFirebaseFirestore();
  final mockAuth = MockFirebaseAuth();
  final mockUser = MockUser();
  final qRepo = questionRepo ?? MockQuestionRepository();

  // Auth setup
  when(() => mockAuth.currentUser).thenReturn(mockUser);
  when(() => mockUser.uid).thenReturn(_myUid);

  // Firestore data
  await fakeFirestore
      .collection('users')
      .doc(_myUid)
      .set({'username': _myUsername});

  await fakeFirestore
      .collection('sessions')
      .doc(_sessionId)
      .set(sessionDoc ?? _answeringSessionDoc());

  // Question repository
  when(() => qRepo.getQuestionsByIds(
        category: any(named: 'category'),
        ids: any(named: 'ids'),
      )).thenAnswer((_) async => [
        _makeQuestion('0'),
        _makeQuestion('1'),
        _makeQuestion('2'),
      ]);

  final sessionRepo = FirebaseSessionRepository(firestore: fakeFirestore);

  final svc = MultiplayerGameService(
    sessionId: _sessionId,
    sessionRepository: sessionRepo,
    questionRepository: qRepo,
    auth: mockAuth,
    firestore: fakeFirestore,
  );

  await svc.ready;
  return (service: svc, firestore: fakeFirestore);
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── Initialization ─────────────────────────────────────────────────────────
  group('_initialize / ready', () {
    test('completes successfully with valid auth and session', () async {
      final ctx = await _createService();
      // If we reach this line, ready completed without throwing.
      expect(ctx.service.sessionId, _sessionId);
    });

    test('throws StateError when no authenticated user', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockAuth = MockFirebaseAuth();
      final mockQRepo = MockQuestionRepository();

      when(() => mockAuth.currentUser).thenReturn(null); // no user

      final svc = MultiplayerGameService(
        sessionId: _sessionId,
        sessionRepository: FirebaseSessionRepository(firestore: fakeFirestore),
        questionRepository: mockQRepo,
        auth: mockAuth,
        firestore: fakeFirestore,
      );

      await expectLater(svc.ready, throwsA(isA<StateError>()));
    });

    test('throws StateError when session document does not exist', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockAuth = MockFirebaseAuth();
      final mockUser = MockUser();
      final mockQRepo = MockQuestionRepository();

      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(_myUid);

      await fakeFirestore
          .collection('users')
          .doc(_myUid)
          .set({'username': _myUsername});
      // Session document intentionally not created.

      final svc = MultiplayerGameService(
        sessionId: 'nonexistent_session',
        sessionRepository: FirebaseSessionRepository(firestore: fakeFirestore),
        questionRepository: mockQRepo,
        auth: mockAuth,
        firestore: fakeFirestore,
      );

      await expectLater(svc.ready, throwsA(isA<StateError>()));
    });

    test('username falls back to empty string when missing in Firestore', () async {
      final fakeFirestore = FakeFirebaseFirestore();
      final mockAuth = MockFirebaseAuth();
      final mockUser = MockUser();
      final mockQRepo = MockQuestionRepository();

      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockUser.uid).thenReturn(_myUid);

      // User document without 'username' field.
      await fakeFirestore.collection('users').doc(_myUid).set({});
      await fakeFirestore
          .collection('sessions')
          .doc(_sessionId)
          .set(_answeringSessionDoc());

      when(() => mockQRepo.getQuestionsByIds(
            category: any(named: 'category'),
            ids: any(named: 'ids'),
          )).thenAnswer((_) async => []);

      final svc = MultiplayerGameService(
        sessionId: _sessionId,
        sessionRepository: FirebaseSessionRepository(firestore: fakeFirestore),
        questionRepository: mockQRepo,
        auth: mockAuth,
        firestore: fakeFirestore,
      );

      await svc.ready;
      expect(svc.myUsername, '');
    });
  });

  // ── Public property accessors ──────────────────────────────────────────────
  group('property accessors after successful init', () {
    test('sessionId', () async {
      final ctx = await _createService();
      expect(ctx.service.sessionId, _sessionId);
    });

    test('myUid', () async {
      final ctx = await _createService();
      expect(ctx.service.myUid, _myUid);
    });

    test('myUsername', () async {
      final ctx = await _createService();
      expect(ctx.service.myUsername, _myUsername);
    });

    test('questions are loaded from repository', () async {
      final ctx = await _createService();
      expect(ctx.service.questions.length, 3);
      expect(ctx.service.questions.map((q) => q.id), ['0', '1', '2']);
    });

    test('getQuestionsByIds is called with the ids from the session document', () async {
      final mockQRepo = MockQuestionRepository();
      List<String>? capturedIds;

      when(() => mockQRepo.getQuestionsByIds(
            category: any(named: 'category'),
            ids: captureAny(named: 'ids'),
          )).thenAnswer((inv) async {
        capturedIds =
            (inv.namedArguments[const Symbol('ids')] as List).cast<String>();
        return capturedIds!.map((id) => _makeQuestion(id)).toList();
      });

      await _createService(questionRepo: mockQRepo);
      expect(capturedIds, ['0', '1', '2']);
    });
  });

  // ── buildLiveGameStateStream / _parse ──────────────────────────────────────
  group('buildLiveGameStateStream — _parse behavior', () {
    test('emits LiveGameState with answering status', () async {
      final ctx = await _createService();
      final state = await ctx.service.buildLiveGameStateStream().first;

      expect(state.status, SessionStatus.answering);
      expect(state.sessionId, _sessionId);
      expect(state.myUid, _myUid);
      expect(state.currentQuestionIndex, 0);
      expect(state.questionIds, ['0', '1', '2']);
    });

    test('maps inProgress+answering -> SessionStatus.answering', () async {
      final ctx = await _createService(
        sessionDoc: _answeringSessionDoc(),
      );
      final state = await ctx.service.buildLiveGameStateStream().first;
      expect(state.status, SessionStatus.answering);
    });

    test('maps inProgress+resolving -> SessionStatus.resolving with RoundResult', () async {
      final ctx = await _createService();

      // Update to resolving phase with a round result.
      await ctx.firestore.collection('sessions').doc(_sessionId).set({
        ..._answeringSessionDoc(),
        'phase': 'resolving',
        'lastRoundResult': {
          'eliminatedUid': 'uid2',
          'eliminatedUsername': 'User2',
          'lotteryOccurred': false,
          'lotteryPool': {},
          'opponentLeft': false,
        },
      });

      final state = await ctx.service.buildLiveGameStateStream().first;

      expect(state.status, SessionStatus.resolving);
      expect(state.lastRoundResult, isNotNull);
      expect(state.lastRoundResult!.eliminatedUid, 'uid2');
      expect(state.lastRoundResult!.lotteryOccurred, isFalse);
      expect(state.lastRoundResult!.opponentLeft, isFalse);
    });

    test('maps finished status -> SessionStatus.finished', () async {
      final ctx = await _createService(
        sessionDoc: {
          ..._answeringSessionDoc(),
          'status': 'finished',
          'phase': 'finished',
        },
      );
      final state = await ctx.service.buildLiveGameStateStream().first;
      expect(state.status, SessionStatus.finished);
    });

    test('maps waiting status -> SessionStatus.waiting', () async {
      final ctx = await _createService(
        sessionDoc: {
          ..._answeringSessionDoc(),
          'status': 'waiting',
          'phase': 'answering',
        },
      );
      final state = await ctx.service.buildLiveGameStateStream().first;
      expect(state.status, SessionStatus.waiting);
    });

    test('parses players list correctly', () async {
      final ctx = await _createService(
        sessionDoc: _answeringSessionDoc(players: {
          'uid1': {
            'username': 'Alice',
            'profilePicture': 'alice.png',
            'isEliminated': false,
            'lotteryTickets': 2,
          },
          'uid2': {
            'username': 'Bob',
            'profilePicture': 'bob.png',
            'isEliminated': true,
            'lotteryTickets': 0,
          },
        }),
      );
      final state = await ctx.service.buildLiveGameStateStream().first;

      expect(state.players.length, 2);

      final alice = state.players.firstWhere((p) => p.uid == 'uid1');
      expect(alice.username, 'Alice');
      expect(alice.isEliminated, isFalse);
      expect(alice.lotteryTickets, 2);

      final bob = state.players.firstWhere((p) => p.uid == 'uid2');
      expect(bob.username, 'Bob');
      expect(bob.isEliminated, isTrue);
    });

    test('RoundResult with opponentLeft=true is parsed correctly', () async {
      final ctx = await _createService();

      await ctx.firestore.collection('sessions').doc(_sessionId).set({
        ..._answeringSessionDoc(),
        'phase': 'resolving',
        'lastRoundResult': {
          'eliminatedUid': null,
          'eliminatedUsername': null,
          'lotteryOccurred': false,
          'lotteryPool': {},
          'opponentLeft': true,
        },
      });

      final state = await ctx.service.buildLiveGameStateStream().first;

      expect(state.lastRoundResult!.opponentLeft, isTrue);
      expect(state.lastRoundResult!.eliminatedUid, isNull);
    });

    test('RoundResult lotteryOccurred and lotteryPool are parsed', () async {
      final ctx = await _createService();

      await ctx.firestore.collection('sessions').doc(_sessionId).set({
        ..._answeringSessionDoc(),
        'phase': 'resolving',
        'lastRoundResult': {
          'eliminatedUid': 'uid1',
          'eliminatedUsername': _myUsername,
          'lotteryOccurred': true,
          'lotteryPool': {'uid1': 2, 'uid2': 1},
          'opponentLeft': false,
        },
      });

      final state = await ctx.service.buildLiveGameStateStream().first;

      expect(state.lastRoundResult!.lotteryOccurred, isTrue);
      expect(state.lastRoundResult!.lotteryPool, {'uid1': 2, 'uid2': 1});
    });

    test('throws StateError when resolving phase has no lastRoundResult', () async {
      final ctx = await _createService(
        sessionDoc: {
          ..._answeringSessionDoc(),
          'phase': 'resolving',
          'lastRoundResult': null,
        },
      );

      await expectLater(
        ctx.service.buildLiveGameStateStream(),
        emitsError(isA<StateError>()),
      );
    });

    test('stream emits updated state when session document changes', () async {
      final ctx = await _createService();
      final stream = ctx.service.buildLiveGameStateStream();

      // First emission: answering
      final first = await stream.first;
      expect(first.status, SessionStatus.answering);

      // Move to question index 1
      await ctx.firestore
          .collection('sessions')
          .doc(_sessionId)
          .update({'currentQuestionIndex': 1});

      final second = await ctx.service.buildLiveGameStateStream().first;
      expect(second.currentQuestionIndex, 1);
    });
  });

  // ── submitAnswer ───────────────────────────────────────────────────────────
  group('submitAnswer', () {
    test('delegates to sessionRepository.submitAnswer with correct args', () async {
      final ctx = await _createService();

      await ctx.service.submitAnswer(
        roundIndex: 2,
        questionId: '2',
        answer: 'CorrectAnswer',
      );

      // Verify the answer was written to Firestore 'answers' subcollection.
      final snap = await ctx.firestore
          .collection('sessions')
          .doc(_sessionId)
          .collection('answers')
          .doc('${_myUid}_2')
          .get();

      expect(snap.exists, isTrue);
      expect(snap.data()!['uid'], _myUid);
      expect(snap.data()!['roundIndex'], 2);
      expect(snap.data()!['questionId'], '2');
      expect(snap.data()!['answer'], 'CorrectAnswer');
    });
  });

  // ── leaveGame ──────────────────────────────────────────────────────────────
  group('leaveGame', () {
    test('marks uid as eliminated in Firestore session document', () async {
      final ctx = await _createService();

      await ctx.service.leaveGame();

      final snap = await ctx.firestore
          .collection('sessions')
          .doc(_sessionId)
          .get();

      // After leaveGame the player should be marked as eliminated
      // (FirebaseSessionRepository.leaveGame sets isEliminated: true).
      final playerData =
          (snap.data()!['players'] as Map)[_myUid] as Map<String, dynamic>;
      expect(playerData['isEliminated'], isTrue);
    });
  });

  // ── fetchFinalSessionData ──────────────────────────────────────────────────
  group('fetchFinalSessionData', () {
    test('throws StateError when archive document does not exist', () async {
      final ctx = await _createService();

      // sessions_archive is empty — nothing archived yet.
      await expectLater(
        ctx.service.fetchFinalSessionData(),
        throwsA(isA<StateError>()),
      );
    });

    test('returns MultiplayerSessionData from sessions_archive', () async {
      final ctx = await _createService();

      final archiveData = {
        'sessionId': _sessionId,
        'categoryId': _categoryId,
        'gameMode': 'casual',
        'sessionStartTime': '2024-01-01T10:00:00.000Z',
        'gameStartTime': '2024-01-01T10:01:00.000Z',
        'endTime': '2024-01-01T10:30:00.000Z',
        'playerResults': [
          {
            'uid': _myUid,
            'username': _myUsername,
            'placement': 1,
            'correctAnswers': 3,
            'totalAnswers': 3,
            'eliminationRound': 0,
            'lotteryTimesIn': 0,
          }
        ],
        'rounds': [],
      };

      await ctx.firestore
          .collection('sessions_archive')
          .doc(_sessionId)
          .set(archiveData);

      final result = await ctx.service.fetchFinalSessionData();

      expect(result, isA<MultiplayerSessionData>());
      expect(result.sessionId, _sessionId);
      expect(result.winner?.uid, _myUid);
    });
  });
}
