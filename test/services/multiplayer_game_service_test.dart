import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/game_answer.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/models/session_snapshot.dart';
import 'package:triviaapp/models/session_status.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/session_repository.dart';
import 'package:triviaapp/services/multiplayer_game_service.dart';
import '../fakes.dart';
import '../support/session_fixtures.dart';

class _Sessions extends Fake implements SessionRepository {
  SessionSnapshot current = sessionSnapshot();
  final changes = StreamController<SessionSnapshot>.broadcast();
  String? uid, sessionId, questionId, answer;
  int? index;
  bool failArchive = false;
  @override
  Stream<SessionSnapshot> sessionDocStream(String id) async* {
    sessionId = id;
    yield current;
    yield* changes.stream;
  }

  void emit(SessionSnapshot value) {
    current = value;
    changes.add(value);
  }

  @override
  Future<GameAnswer> submitAnswer({
    required String sessionId,
    required String uid,
    required int roundIndex,
    required String questionId,
    required String answer,
  }) async {
    this.sessionId = sessionId;
    this.uid = uid;
    index = roundIndex;
    this.questionId = questionId;
    this.answer = answer;
    return const GameAnswer(isCorrect: true, correctAnswers: ['A']);
  }

  @override
  Future<void> leaveGame({
    required String sessionId,
    required String uid,
  }) async {
    this.sessionId = sessionId;
    this.uid = uid;
  }

  @override
  Future<MultiplayerSessionData> fetchArchivedSession(String id) async {
    if (failArchive) throw StateError('Missing archive');
    return MultiplayerSessionData.fromJson(archiveDocument());
  }
}

class _Questions extends Fake implements FirebaseQuestionRepository {
  bool fail = false;
  List<String>? ids;
  String? category;
  @override
  Future<List<Question>> getQuestionsByIds({
    required String category,
    required List<String> ids,
  }) async {
    this.ids = ids;
    this.category = category;
    if (fail) throw StateError('Missing question');
    return [
      for (final id in ids)
        Question(
          id: id,
          text: 'Q$id',
          answers: {'A', 'B'},
          type: QuestionType.open4,
          difficulty: Difficulty.easy,
        ),
    ];
  }
}

void main() {
  late _Sessions sessions;
  late _Questions questions;
  late FakeAuthRepository auth;
  late FakeProfileRepository profile;
  MultiplayerGameService service() => MultiplayerGameService(
    sessionId: 'room',
    sessionRepository: sessions,
    questionRepository: questions,
    authRepository: auth,
    profileRepository: profile,
  );
  setUp(() {
    sessions = _Sessions();
    questions = _Questions();
    auth = FakeAuthRepository()..signedIn = true;
    profile = FakeProfileRepository()
      ..getResult = makeProfile(uid: 'uid1', username: 'Player');
  });
  tearDown(() => sessions.changes.close());

  test(
    'initializes identity and authoritative ordered questions without Firebase',
    () async {
      final game = service();
      await game.ready;
      expect(game.sessionId, 'room');
      expect(game.myUid, 'uid1');
      expect(game.myUsername, 'Player');
      expect(questions.ids, ['0', '1', '2']);
      expect(questions.category, 'general');
      expect(game.questions.map((q) => q.id), ['0', '1', '2']);
      expect(() => game.questions.clear(), throwsUnsupportedError);
    },
  );
  test('rejects unauthenticated initialization', () async {
    auth.signedIn = false;
    await expectLater(service().ready, throwsStateError);
  });
  test('propagates profile loading failure', () async {
    profile.getError = Exception('Profile unavailable');
    await expectLater(service().ready, throwsException);
  });
  test('rejects an empty question pool', () async {
    sessions.current = sessionSnapshot(status: 'waiting', ids: []);
    await expectLater(service().ready, throwsStateError);
  });
  test('propagates an authoritative question load failure', () async {
    questions.fail = true;
    await expectLater(service().ready, throwsStateError);
  });
  test(
    'projects typed snapshots without conflating status and phase',
    () async {
      sessions.current = sessionSnapshot(phase: 'resolving');
      final state = await service().buildLiveGameStateStream().first;
      expect(state.status, SessionStatus.inProgress);
      expect(state.phase, RoundPhase.resolving);
      expect(state.lastRoundResult!.eliminatedUid, 'uid2');
      expect(state.myUid, 'uid1');
    },
  );
  test(
    'withholds finished until results are ready and allows subsequent subscription',
    () async {
      final game = service();
      await game.ready;
      final states = <SessionStatus>[];
      final first = Completer<void>(), finished = Completer<void>();
      final sub = game.buildLiveGameStateStream().listen((state) {
        states.add(state.status);
        if (!first.isCompleted) first.complete();
        if (state.status == SessionStatus.finished) finished.complete();
      });
      await first.future;
      sessions.emit(sessionSnapshot(status: 'finished', phase: 'finished'));
      await pumpEventQueue();
      expect(states, [SessionStatus.inProgress]);
      sessions.emit(
        sessionSnapshot(status: 'finished', phase: 'finished', ready: true),
      );
      await finished.future;
      await sub.cancel();
      expect((await game.buildLiveGameStateStream().first).resultsReady, true);
    },
  );
  test(
    'forwards the authenticated profile identity and issued question when answering',
    () async {
      final game = service();
      await game.ready;
      final result = await game.submitAnswer(
        roundIndex: 1,
        questionId: '1',
        answer: 'A',
      );
      expect(
        [
          sessions.sessionId,
          sessions.uid,
          sessions.index,
          sessions.questionId,
          sessions.answer,
        ],
        ['room', 'uid1', 1, '1', 'A'],
      );
      expect(result.isCorrect, true);
    },
  );
  test(
    'leaving awaits initialization and uses the authenticated identity',
    () async {
      final game = service();
      await game.leaveGame();
      expect(sessions.sessionId, 'room');
      expect(sessions.uid, 'uid1');
    },
  );
  test('fetches a complete archive and preserves read failures', () async {
    final game = service();
    await game.ready;
    expect(
      (await game.fetchFinalSessionData()).rounds.single.playerAnswers['uid1'],
      'A',
    );
    sessions.failArchive = true;
    await expectLater(game.fetchFinalSessionData(), throwsStateError);
  });
  test('initializes from an archived snapshot after live cleanup', () async {
    sessions.current = SessionSnapshot.fromArchive('room', archiveDocument());
    final game = service();
    await game.ready;
    expect(
      (await game.buildLiveGameStateStream().first).status,
      SessionStatus.finished,
    );
    expect(game.questions.length, 3);
  });
}
