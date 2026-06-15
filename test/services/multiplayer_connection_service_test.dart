import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';
import 'package:triviaapp/services/multiplayer_connection_service.dart';

// ---------------------------------------------------------------------------
// Mocktail mocks — używane w testach wymagających verify/verifyNever/captureAny
// ---------------------------------------------------------------------------

class MockSessionRepository extends Mock implements FirebaseSessionRepository {}
class MockQuestionRepository extends Mock implements FirebaseQuestionRepository {}

// ---------------------------------------------------------------------------
// Fakes — używane w testach wymagających inspekcji stanu (liczniki wywołań,
// przechwycone argumenty) oraz w testach private game i difficulty
// ---------------------------------------------------------------------------

class _FakeSessionRepo extends Fake implements FirebaseSessionRepository {
  String? waitingSessionId;
  String? privateSessionId;
  String createdSessionId = 'new_session';

  int joinCallCount = 0;
  int createCallCount = 0;
  int removeCallCount = 0;

  /// [joinSession] rzuca [StateError] dla pierwszych [throwOnJoinCount] wywołań.
  int throwOnJoinCount = 0;

  @override
  Future<String?> findWaitingSession({
    required String categoryId,
    required int maxPlayers,
  }) async =>
      waitingSessionId;

  @override
  Future<String?> findPrivateSession({required int entryCode}) async =>
      privateSessionId;

  @override
  Future<String> joinSession({
    required String sessionId,
    required String uid,
    required String username,
  }) async {
    joinCallCount++;
    if (joinCallCount <= throwOnJoinCount) {
      throw StateError('Session $sessionId is full');
    }
    return sessionId;
  }

  @override
  Future<String> createSession({
    required OnlineGameOptions settings,
    required List<String> questionIds,
    required String uid,
    required String username,
  }) async {
    createCallCount++;
    return createdSessionId;
  }

  @override
  Future<void> removePlayer({
    required String sessionId,
    required String uid,
  }) async {
    removeCallCount++;
  }
}

class _FakeQuestionRepo extends Fake implements FirebaseQuestionRepository {
  List<Question> questionsToReturn;
  Difficulty? capturedDifficulty;
  String? capturedCategory;

  _FakeQuestionRepo({required this.questionsToReturn});

  @override
  Future<List<Question>> getQuestions({
    required int limit,
    required String category,
    required List<QuestionType> questionTypes,
    required Difficulty difficulty,
  }) async {
    capturedDifficulty = difficulty;
    capturedCategory = category;
    return questionsToReturn;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Question _makeQuestion(String id) => Question.fromJson({
  'id': id,
  'category': 'general',
  'text': 'Question $id',
  'correctAnswers': ['A'],
  'wrongAnswers': ['B', 'C', 'D'],
  'difficulty': 'medium',
  'type': 'open4',
});

List<Question> _makeQuestions(int count) =>
    List.generate(count, (i) => _makeQuestion('$i'));

// ---------------------------------------------------------------------------
// Shared constants
// ---------------------------------------------------------------------------

const _uid      = 'uid1';
const _username = 'TestUser';

const _publicSettings  = OnlineGameOptions(categoryId: 'general', maxPlayers: 2);
const _privateSettings = OnlineGameOptions(
  categoryId: 'general',
  maxPlayers: 4,
  entryCode: 123456,
);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ══════════════════════════════════════════════════════════════════════════
  // Sekcja A — mocktail: granularne verify/verifyNever/captureAny
  // ══════════════════════════════════════════════════════════════════════════

  group('connectPlayer [mocktail] — joins existing waiting session', () {
    late MockSessionRepository mockSessionRepo;
    late MockQuestionRepository mockQuestionRepo;
    late MultiplayerConnectionService service;

    const existingSessionId = 'sess_existing';
    final questions = _makeQuestions(10);

    setUp(() {
      mockSessionRepo  = MockSessionRepository();
      mockQuestionRepo = MockQuestionRepository();
      service = MultiplayerConnectionService(
        sessionRepository: mockSessionRepo,
        questionRepository: mockQuestionRepo,
      );

      when(() => mockSessionRepo.findWaitingSession(
        categoryId: _publicSettings.categoryId,
        maxPlayers: _publicSettings.maxPlayers,
      )).thenAnswer((_) async => existingSessionId);

      when(() => mockSessionRepo.joinSession(
        sessionId: existingSessionId,
        uid: _uid,
        username: _username,
      )).thenAnswer((_) async => existingSessionId);
    });

    test('returns the existing session id', () async {
      final result = await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: _publicSettings,
      );
      expect(result, existingSessionId);
    });

    test('calls joinSession exactly once', () async {
      await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: _publicSettings,
      );
      verify(() => mockSessionRepo.joinSession(
        sessionId: existingSessionId,
        uid: _uid,
        username: _username,
      )).called(1);
    });

    test('never calls createSession', () async {
      await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: _publicSettings,
      );
      verifyNever(() => mockSessionRepo.createSession(
        settings: any(named: 'settings'),
        questionIds: any(named: 'questionIds'),
        uid: any(named: 'uid'),
        username: any(named: 'username'),
      ));
    });

    test('never calls getQuestions', () async {
      await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: _publicSettings,
      );
      verifyNever(() => mockQuestionRepo.getQuestions(
        limit: any(named: 'limit'),
        category: any(named: 'category'),
        questionTypes: any(named: 'questionTypes'),
        difficulty: any(named: 'difficulty'),
      ));
    });
  });

  group('connectPlayer [mocktail] — creates new session when none found', () {
    late MockSessionRepository mockSessionRepo;
    late MockQuestionRepository mockQuestionRepo;
    late MultiplayerConnectionService service;

    const newSessionId = 'sess_new';
    final questions = _makeQuestions(10);

    setUp(() {
      mockSessionRepo  = MockSessionRepository();
      mockQuestionRepo = MockQuestionRepository();
      service = MultiplayerConnectionService(
        sessionRepository: mockSessionRepo,
        questionRepository: mockQuestionRepo,
      );

      when(() => mockSessionRepo.findWaitingSession(
        categoryId: any(named: 'categoryId'),
        maxPlayers: any(named: 'maxPlayers'),
      )).thenAnswer((_) async => null);

      when(() => mockQuestionRepo.getQuestions(
        limit: any(named: 'limit'),
        category: _publicSettings.categoryId,
        questionTypes: any(named: 'questionTypes'),
        difficulty: any(named: 'difficulty'),
      )).thenAnswer((_) async => questions);

      when(() => mockSessionRepo.createSession(
        settings: any(named: 'settings'),
        questionIds: any(named: 'questionIds'),
        uid: any(named: 'uid'),
        username: any(named: 'username'),
      )).thenAnswer((_) async => newSessionId);
    });

    test('returns the new session id', () async {
      final result = await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: _publicSettings,
      );
      expect(result, newSessionId);
    });

    test('calls getQuestions with correct category and all QuestionTypes', () async {
      await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: _publicSettings,
      );
      verify(() => mockQuestionRepo.getQuestions(
        limit: any(named: 'limit'),
        category: _publicSettings.categoryId,
        questionTypes: QuestionType.values,
        difficulty: any(named: 'difficulty'),
      )).called(1);
    });

    test('calls createSession with question ids derived from fetched questions', () async {
      final captured = <String>[];

      when(() => mockSessionRepo.createSession(
        settings: any(named: 'settings'),
        questionIds: captureAny(named: 'questionIds'),
        uid: _uid,
        username: _username,
      )).thenAnswer((inv) async {
        captured.addAll(
          (inv.namedArguments[const Symbol('questionIds')] as List).cast<String>(),
        );
        return newSessionId;
      });

      await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: _publicSettings,
      );

      expect(captured, questions.map((q) => q.id).toList());
    });

    test('calls createSession with correct uid and username', () async {
      await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: _publicSettings,
      );
      verify(() => mockSessionRepo.createSession(
        settings: any(named: 'settings'),
        questionIds: any(named: 'questionIds'),
        uid: _uid,
        username: _username,
      )).called(1);
    });

    test('never calls joinSession', () async {
      await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: _publicSettings,
      );
      verifyNever(() => mockSessionRepo.joinSession(
        sessionId: any(named: 'sessionId'),
        uid: any(named: 'uid'),
        username: any(named: 'username'),
      ));
    });
  });

  group('connectPlayer [mocktail] — throws when question list is empty', () {
    late MockSessionRepository mockSessionRepo;
    late MockQuestionRepository mockQuestionRepo;
    late MultiplayerConnectionService service;

    setUp(() {
      mockSessionRepo  = MockSessionRepository();
      mockQuestionRepo = MockQuestionRepository();
      service = MultiplayerConnectionService(
        sessionRepository: mockSessionRepo,
        questionRepository: mockQuestionRepo,
      );
    });

    test('throws StateError with "No questions available" message', () async {
      when(() => mockSessionRepo.findWaitingSession(
        categoryId: any(named: 'categoryId'),
        maxPlayers: any(named: 'maxPlayers'),
      )).thenAnswer((_) async => null);

      when(() => mockQuestionRepo.getQuestions(
        limit: any(named: 'limit'),
        category: any(named: 'category'),
        questionTypes: any(named: 'questionTypes'),
        difficulty: any(named: 'difficulty'),
      )).thenAnswer((_) async => []);

      await expectLater(
        service.connectPlayer(
          uid: _uid,
          username: _username,
          settings: _publicSettings,
        ),
        throwsA(
          isA<StateError>().having(
                (e) => e.message,
            'message',
            contains('No questions available'),
          ),
        ),
      );
    });
  });

  group('connectPlayer [mocktail] — retry on StateError', () {
    late MockSessionRepository mockSessionRepo;
    late MockQuestionRepository mockQuestionRepo;
    late MultiplayerConnectionService service;

    setUp(() {
      mockSessionRepo  = MockSessionRepository();
      mockQuestionRepo = MockQuestionRepository();
      service = MultiplayerConnectionService(
        sessionRepository: mockSessionRepo,
        questionRepository: mockQuestionRepo,
      );
    });

    test('succeeds on second attempt after StateError from joinSession', () async {
      var findCallCount = 0;

      when(() => mockSessionRepo.findWaitingSession(
        categoryId: any(named: 'categoryId'),
        maxPlayers: any(named: 'maxPlayers'),
      )).thenAnswer((_) async {
        findCallCount++;
        return findCallCount == 1 ? 'contended_session' : null;
      });

      when(() => mockSessionRepo.joinSession(
        sessionId: any(named: 'sessionId'),
        uid: any(named: 'uid'),
        username: any(named: 'username'),
      )).thenThrow(StateError('Session is full'));

      when(() => mockQuestionRepo.getQuestions(
        limit: any(named: 'limit'),
        category: any(named: 'category'),
        questionTypes: any(named: 'questionTypes'),
        difficulty: any(named: 'difficulty'),
      )).thenAnswer((_) async => [_makeQuestion('0')]);

      when(() => mockSessionRepo.createSession(
        settings: any(named: 'settings'),
        questionIds: any(named: 'questionIds'),
        uid: any(named: 'uid'),
        username: any(named: 'username'),
      )).thenAnswer((_) async => 'new_session');

      final result = await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: _publicSettings,
      );

      expect(result, 'new_session');
      expect(findCallCount, greaterThanOrEqualTo(2));
    });

    test('throws StateError after all attempts fail on joinSession', () async {
      when(() => mockSessionRepo.findWaitingSession(
        categoryId: any(named: 'categoryId'),
        maxPlayers: any(named: 'maxPlayers'),
      )).thenAnswer((_) async => 'always_full_session');

      when(() => mockSessionRepo.joinSession(
        sessionId: any(named: 'sessionId'),
        uid: any(named: 'uid'),
        username: any(named: 'username'),
      )).thenThrow(StateError('Session is full'));

      await expectLater(
        service.connectPlayer(
          uid: _uid,
          username: _username,
          settings: _publicSettings,
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('retries exactly 3 times (maxMatchmakingAttempts) before throwing', () async {
      var callCount = 0;

      when(() => mockSessionRepo.findWaitingSession(
        categoryId: any(named: 'categoryId'),
        maxPlayers: any(named: 'maxPlayers'),
      )).thenAnswer((_) async {
        callCount++;
        throw StateError('Always fails at find');
      });

      await expectLater(
        service.connectPlayer(
          uid: _uid,
          username: _username,
          settings: _publicSettings,
        ),
        throwsA(isA<StateError>()),
      );

      expect(callCount, 3);
    });
  });

  group('disconnectPlayer [mocktail]', () {
    late MockSessionRepository mockSessionRepo;
    late MockQuestionRepository mockQuestionRepo;
    late MultiplayerConnectionService service;

    const sessionId = 'sess1';

    setUp(() {
      mockSessionRepo  = MockSessionRepository();
      mockQuestionRepo = MockQuestionRepository();
      service = MultiplayerConnectionService(
        sessionRepository: mockSessionRepo,
        questionRepository: mockQuestionRepo,
      );
    });

    test('delegates to sessionRepository.removePlayer with correct args', () async {
      when(() => mockSessionRepo.removePlayer(
        sessionId: sessionId,
        uid: _uid,
      )).thenAnswer((_) async {});

      await service.disconnectPlayer(sessionId: sessionId, uid: _uid);

      verify(() => mockSessionRepo.removePlayer(
        sessionId: sessionId,
        uid: _uid,
      )).called(1);
    });

    test('propagates exception from removePlayer', () async {
      when(() => mockSessionRepo.removePlayer(
        sessionId: any(named: 'sessionId'),
        uid: any(named: 'uid'),
      )).thenThrow(Exception('network error'));

      await expectLater(
        service.disconnectPlayer(sessionId: sessionId, uid: _uid),
        throwsA(isA<Exception>()),
      );
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // Sekcja B — fakes: testy private game, difficulty i join/create liczniki
  // ══════════════════════════════════════════════════════════════════════════

  group('connectPlayer [fakes] — public matchmaking: call counts', () {
    late _FakeSessionRepo sessionRepo;
    late _FakeQuestionRepo questionRepo;
    late MultiplayerConnectionService service;

    final tenQuestions = _makeQuestions(10);

    setUp(() {
      sessionRepo  = _FakeSessionRepo();
      questionRepo = _FakeQuestionRepo(questionsToReturn: tenQuestions);
      service = MultiplayerConnectionService(
        sessionRepository: sessionRepo,
        questionRepository: questionRepo,
      );
    });

    test('joins existing: joinCallCount == 1, createCallCount == 0', () async {
      sessionRepo.waitingSessionId = 'existing_session';

      final result = await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: _publicSettings,
      );

      expect(result, 'existing_session');
      expect(sessionRepo.joinCallCount, 1);
      expect(sessionRepo.createCallCount, 0);
    });

    test('creates new: createCallCount == 1, joinCallCount == 0', () async {
      sessionRepo.waitingSessionId = null;

      final result = await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: _publicSettings,
      );

      expect(result, sessionRepo.createdSessionId);
      expect(sessionRepo.createCallCount, 1);
      expect(sessionRepo.joinCallCount, 0);
    });

    test('retries and succeeds after transient StateError: joinCallCount == 2', () async {
      sessionRepo.waitingSessionId = 'busy_session';
      sessionRepo.throwOnJoinCount = 1;

      final result = await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: _publicSettings,
      );

      expect(result, 'busy_session');
      expect(sessionRepo.joinCallCount, 2);
    });

    test('exhausts retries: joinCallCount == 3 (maxMatchmakingAttempts)', () async {
      sessionRepo.waitingSessionId = 'always_full';
      sessionRepo.throwOnJoinCount = 100;

      await expectLater(
        service.connectPlayer(
          uid: _uid,
          username: _username,
          settings: _publicSettings,
        ),
        throwsA(isA<StateError>()),
      );

      expect(sessionRepo.joinCallCount, 3);
    });
  });

  group('connectPlayer [fakes] — category and difficulty passthrough', () {
    late _FakeSessionRepo sessionRepo;
    late _FakeQuestionRepo questionRepo;
    late MultiplayerConnectionService service;

    setUp(() {
      sessionRepo  = _FakeSessionRepo();
      questionRepo = _FakeQuestionRepo(questionsToReturn: _makeQuestions(10));
      service = MultiplayerConnectionService(
        sessionRepository: sessionRepo,
        questionRepository: questionRepo,
      );
      sessionRepo.waitingSessionId = null;
    });

    test('passes the correct category to the question repository', () async {
      const settings = OnlineGameOptions(categoryId: 'history', maxPlayers: 2);

      await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: settings,
      );

      expect(questionRepo.capturedCategory, 'history');
    });

    test('passes the difficulty from settings to the question repository', () async {
      const settings = OnlineGameOptions(
        categoryId: 'general',
        maxPlayers: 2,
        difficulty: Difficulty.hard,
      );

      await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: settings,
      );

      expect(questionRepo.capturedDifficulty, Difficulty.hard);
    });
  });

  group('connectPlayer [fakes] — private game', () {
    late _FakeSessionRepo sessionRepo;
    late _FakeQuestionRepo questionRepo;
    late MultiplayerConnectionService service;

    setUp(() {
      sessionRepo  = _FakeSessionRepo();
      questionRepo = _FakeQuestionRepo(questionsToReturn: _makeQuestions(10));
      service = MultiplayerConnectionService(
        sessionRepository: sessionRepo,
        questionRepository: questionRepo,
      );
    });

    test('joins existing private session when the code matches', () async {
      sessionRepo.privateSessionId = 'private_session';

      final result = await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: _privateSettings,
      );

      expect(result, 'private_session');
      expect(sessionRepo.joinCallCount, 1);
      expect(sessionRepo.createCallCount, 0);
    });

    test('creates a new private session when no session with the code exists', () async {
      sessionRepo.privateSessionId = null;

      final result = await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: _privateSettings,
      );

      expect(result, sessionRepo.createdSessionId);
      expect(sessionRepo.createCallCount, 1);
      expect(sessionRepo.joinCallCount, 0);
    });

    test('does not search public sessions for a private connection', () async {
      // Publiczna sesja istnieje, ale private routing musi ją ignorować.
      sessionRepo.waitingSessionId  = 'public_session';
      sessionRepo.privateSessionId  = 'private_session';

      final result = await service.connectPlayer(
        uid: _uid,
        username: _username,
        settings: _privateSettings,
      );

      expect(result, 'private_session');
    });
  });

  group('disconnectPlayer [fakes]', () {
    late _FakeSessionRepo sessionRepo;
    late MultiplayerConnectionService service;

    setUp(() {
      sessionRepo = _FakeSessionRepo();
      service = MultiplayerConnectionService(
        sessionRepository: sessionRepo,
        questionRepository: _FakeQuestionRepo(questionsToReturn: []),
      );
    });

    test('delegates to removePlayer: removeCallCount == 1', () async {
      await service.disconnectPlayer(sessionId: 'sid1', uid: _uid);
      expect(sessionRepo.removeCallCount, 1);
    });
  });
}