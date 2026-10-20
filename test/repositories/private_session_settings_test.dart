import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

List<Question> _questions(int count) => List.generate(
  count,
  (i) => Question(
    id: 'question-$i',
    text: 'Q$i',
    correctAnswers: {'A'},
    wrongAnswers: {'B'},
    type: QuestionType.open4,
    difficulty: Difficulty.hard,
  ),
);

class _Questions extends Fake implements FirebaseQuestionRepository {
  List<Question>? result;
  Completer<List<Question>>? pending;
  final requested = Completer<void>();
  String? category;
  Difficulty? difficulty;
  int? limit;

  @override
  Future<List<Question>> getQuestions({
    required int limit,
    required String category,
    required List<QuestionType> questionTypes,
    required Difficulty difficulty,
  }) async {
    this.limit = limit;
    this.category = category;
    this.difficulty = difficulty;
    if (!requested.isCompleted) requested.complete();
    return pending?.future ?? Future.value(result ?? _questions(limit));
  }
}

class _Profile extends Fake implements FirebaseProfileRepository {
  @override
  Future<ProfileData> getProfileData() async =>
      const ProfileData(uid: 'host', username: 'Host');
}

void main() {
  late FakeFirebaseFirestore db;
  late _Questions questions;
  late FirebaseSessionRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    questions = _Questions();
    repo = FirebaseSessionRepository(
      firestore: db,
      profileRepo: _Profile(),
      questionRepository: questions,
    );
  });

  Future<void> seed({List<String> players = const ['host', 'guest']}) =>
      db.collection('sessions').doc('room').set({
        'status': 'waiting',
        'phase': 'answering',
        'isPrivate': true,
        'categoryId': 'general',
        'difficulty': 'medium',
        'questionTimeLimit': 30,
        'maxPlayers': 2,
        'settingsVersion': 0,
        'questionIds': ['old-1', 'old-2', 'old-3'],
        'playerUids': players,
      });

  Future<void> save({String category = 'science', int maxPlayers = 3}) =>
      repo.updateSessionSettings(
        sessionId: 'room',
        categoryId: category,
        maxPlayers: maxPlayers,
        questionTimeLimit: 20,
        difficulty: Difficulty.hard,
      );

  test('persists difficulty and version on lobby creation', () async {
    final id = await repo.createSession(
      settings: const OnlineGameOptions(
        categoryId: 'science',
        difficulty: Difficulty.hard,
        entryCode: 123456,
      ),
      questionIds: [],
      uid: 'host',
      username: 'Host',
    );
    final data = (await db.collection('sessions').doc(id).get()).data()!;
    expect(data['difficulty'], 'hard');
    expect(data['settingsVersion'], 0);
    expect(data['questionIds'], isEmpty);
    expect(data['status'], 'waiting');
  });

  test(
    'save invalidates the old pool and start commits the new pool',
    () async {
      await seed();
      await save();
      final ref = db.collection('sessions').doc('room');
      var data = (await ref.get()).data()!;
      expect(data['questionIds'], isEmpty);
      expect(data['settingsVersion'], 1);

      await repo.startSession(sessionId: 'room');

      data = (await ref.get()).data()!;
      expect(questions.category, 'science');
      expect(questions.difficulty, Difficulty.hard);
      expect(questions.limit, 6);
      expect(data['questionIds'], List.generate(6, (i) => 'question-$i'));
      expect(data['status'], 'inProgress');
      expect(
        (await ref.collection('roundCounters').doc('0').get()).exists,
        isTrue,
      );
    },
  );

  test('does not start with an insufficient or duplicate pool', () async {
    await seed();
    questions.result = _questions(2);
    await expectLater(repo.startSession(sessionId: 'room'), throwsStateError);
    questions.result = List.filled(3, _questions(1).single);
    await expectLater(repo.startSession(sessionId: 'room'), throwsStateError);
    final ref = db.collection('sessions').doc('room');
    expect((await ref.get()).data()!['status'], 'waiting');
    expect(
      (await ref.collection('roundCounters').doc('0').get()).exists,
      isFalse,
    );
  });

  test(
    'rejects configuration changes while questions are being loaded',
    () async {
      await seed();
      questions.pending = Completer<List<Question>>();
      final attempt = expectLater(
        repo.startSession(sessionId: 'room'),
        throwsStateError,
      );
      await questions.requested.future;
      await save();
      questions.pending!.complete(_questions(3));
      await attempt;

      final ref = db.collection('sessions').doc('room');
      final data = (await ref.get()).data()!;
      expect(data['status'], 'waiting');
      expect(data['categoryId'], 'science');
      expect(data['questionIds'], isEmpty);
      expect(
        (await ref.collection('roundCounters').doc('0').get()).exists,
        isFalse,
      );
    },
  );

  test('cannot update settings after a completed start', () async {
    await seed();
    await repo.startSession(sessionId: 'room');
    await expectLater(save(), throwsStateError);
    final data = (await db.collection('sessions').doc('room').get()).data()!;
    expect(data['categoryId'], 'general');
    expect(data['settingsVersion'], 0);
  });

  test('cannot lower capacity below the joined player count', () async {
    await seed(players: ['host', 'guest', 'third']);
    await expectLater(save(maxPlayers: 2), throwsStateError);
    expect(
      (await db.collection('sessions').doc('room').get())
          .data()!['settingsVersion'],
      0,
    );
  });

  test('cannot start alone', () async {
    await seed(players: ['host']);
    await expectLater(repo.startSession(sessionId: 'room'), throwsStateError);
    expect(
      (await db.collection('sessions').doc('room').get()).data()!['status'],
      'waiting',
    );
  });

  test('public creation rejects an insufficient pool before writing', () async {
    await expectLater(
      repo.createSession(
        settings: const OnlineGameOptions(categoryId: 'general'),
        questionIds: ['a', 'b'],
        uid: 'host',
        username: 'Host',
      ),
      throwsStateError,
    );
    expect((await db.collection('sessions').get()).docs, isEmpty);
  });

  test('public auto-start rejects a legacy incomplete pool', () async {
    await seed(players: ['host']);
    final ref = db.collection('sessions').doc('room');
    await ref.update({
      'isPrivate': false,
      'questionIds': ['only-one'],
    });
    await expectLater(
      repo.joinSession(sessionId: 'room', uid: 'guest', username: 'Guest'),
      throwsStateError,
    );
    final data = (await ref.get()).data()!;
    expect(data['status'], 'waiting');
    expect(data['playerUids'], ['host']);
  });

  test(
    'does not start if another start finishes during question loading',
    () async {
      await seed();
      questions.pending = Completer<List<Question>>();
      final attempt = expectLater(
        repo.startSession(sessionId: 'room'),
        throwsStateError,
      );
      await questions.requested.future;
      final ref = db.collection('sessions').doc('room');
      await ref.update({
        'status': 'inProgress',
        'questionIds': ['other-a', 'other-b', 'other-c'],
      });
      questions.pending!.complete(_questions(3));
      await attempt;
      expect((await ref.get()).data()!['questionIds'], [
        'other-a',
        'other-b',
        'other-c',
      ]);
    },
  );

  for (final settings in [
    const OnlineGameOptions(categoryId: ''),
    const OnlineGameOptions(categoryId: 'general/other'),
    const OnlineGameOptions(categoryId: 'general', maxPlayers: 1),
    const OnlineGameOptions(categoryId: 'general', maxPlayers: 11),
    const OnlineGameOptions(categoryId: 'general', questionTimeLimit: 15),
  ]) {
    test(
      'rejects invalid settings ${settings.categoryId}/${settings.maxPlayers}/${settings.questionTimeLimit}',
      () async {
        await expectLater(
          repo.createSession(
            settings: settings,
            questionIds: ['a', 'b', 'c'],
            uid: 'host',
            username: 'Host',
          ),
          throwsArgumentError,
        );
        expect((await db.collection('sessions').get()).docs, isEmpty);
      },
    );
  }
}
