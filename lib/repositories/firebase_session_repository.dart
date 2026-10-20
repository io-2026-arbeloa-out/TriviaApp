import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';

class FirebaseSessionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseProfileRepository _profileRepo;
  final FirebaseQuestionRepository? _questionRepository;

  FirebaseSessionRepository({
    FirebaseFirestore? firestore,
    FirebaseProfileRepository? profileRepo,
    FirebaseQuestionRepository? questionRepository,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _questionRepository = questionRepository,
        _profileRepo = profileRepo ?? FirebaseProfileRepository();

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('sessions');

  CollectionReference<Map<String, dynamic>> get _archive =>
      _firestore.collection('sessions_archive');

  // ── Matchmaking ────────────────────────────────────────────────────────────

  /// Returns a waiting public session matching [categoryId] and [maxPlayers].
  /// Private sessions (isPrivate == true) are excluded via client-side filter
  /// to avoid requiring an additional composite Firestore index.
  Future<String?> findWaitingSession({
    required String categoryId,
    required int maxPlayers,
  }) async {
    final snap = await _sessions
        .where('status', isEqualTo: 'waiting')
        .where('categoryId', isEqualTo: categoryId)
        .where('maxPlayers', isEqualTo: maxPlayers)
        .limit(10)
        .get();

    for (final doc in snap.docs) {
      if (doc.data()['isPrivate'] != true) return doc.id;
    }
    return null;
  }

  /// Returns a waiting private session identified by [entryCode].
  Future<String?> findPrivateSession({required int entryCode}) async {
    final snap = await _sessions
        .where('status', isEqualTo: 'waiting')
        .where('entryCode', isEqualTo: entryCode)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Future<String> createSession({
    required OnlineGameOptions settings,
    required List<String> questionIds,
    required String uid,
    required String username,
  }) async {
    settings.validate();
    if (!settings.isPrivate) _validateQuestionIds(settings, questionIds);
    final docRef = _sessions.doc();
    final String profilePicture = await _getProfilePicture();

    await docRef.set({
      'status': 'waiting',
      'phase': 'answering',
      'categoryId': settings.categoryId,
      'maxPlayers': settings.maxPlayers,
      'questionTimeLimit': settings.questionTimeLimit,
      'difficulty': settings.difficulty.name,
      'settingsVersion': 0,
      'isPrivate': settings.isPrivate,
      'entryCode': settings.entryCode,
      'questionIds': questionIds,
      'playerUids': [uid],
      'activePlayerCount': 1,
      'currentQuestionIndex': 0,
      'players': {uid: _newPlayerEntry(username, profilePicture)},
      'lastRoundResult': null,
      'rounds': [],
      'createdAt': FieldValue.serverTimestamp(),
      'gameStartTime': null,
      'endTime': null,
    });

    return docRef.id;
  }

  // ── Host control ───────────────────────────────────────────────────────────

  /// Manually starts a private session that is still in [waiting] status.
  /// Creates the first round counter atomically with the status transition.
  Future<void> startSession({required String sessionId}) async {
    final sessionRef = _sessions.doc(sessionId);
    final initial = await sessionRef.get();
    if (!initial.exists) throw StateError('Session $sessionId not found');
    final initialData = initial.data()!;
    if (initialData['status'] != 'waiting') return;
    if (initialData['isPrivate'] != true) {
      throw StateError('Public sessions start when the lobby fills');
    }
    final settings = _readOptions(initialData);
    settings.validate();
    final questions = await (_questionRepository ?? FirebaseQuestionRepository())
        .getQuestions(
      limit: settings.requiredQuestionCount,
      category: settings.categoryId,
      questionTypes: QuestionType.values,
      difficulty: settings.difficulty,
    );
    final questionIds = questions.map((q) => q.id).toList();
    _validateQuestionIds(settings, questionIds);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(sessionRef);
      if (!snap.exists) throw StateError('Session $sessionId not found');

      final data = snap.data()!;
      if (data['status'] != 'waiting') {
        throw StateError('Session is no longer waiting');
      }
      if ((data['settingsVersion'] ?? 0) !=
          (initialData['settingsVersion'] ?? 0) ||
          ['categoryId', 'difficulty', 'maxPlayers', 'questionTimeLimit']
              .any((field) => data[field] != initialData[field])) {
        throw StateError('Lobby settings changed; retry starting the game');
      }

      final playerUids =
      List<String>.from(data['playerUids'] as List? ?? []);
      if (playerUids.length < 2 || playerUids.length > settings.maxPlayers) {
        throw StateError('Invalid number of players to start the game');
      }

      tx.update(sessionRef, {
        'questionIds': questionIds,
        'difficulty': settings.difficulty.name,
        'status': 'inProgress',
        'gameStartTime': FieldValue.serverTimestamp(),
      });

      tx.set(
        sessionRef.collection('roundCounters').doc('0'),
        {
          'validatedCount': 0,
          'targetCount': playerUids.length,
          'incorrectUids': <String>[],
          'validatedUids': <String>[],
          'resolved': false,
        },
      );
    });
  }

  /// Updates mutable lobby settings while the session is still [waiting].
  Future<void> updateSessionSettings({
    required String sessionId,
    required int questionTimeLimit,
    required int maxPlayers,
    required String categoryId,
    required Difficulty difficulty,
  }) async {
    final settings = OnlineGameOptions(
      categoryId: categoryId,
      maxPlayers: maxPlayers,
      questionTimeLimit: questionTimeLimit,
      difficulty: difficulty,
    );
    settings.validate();
    final ref = _sessions.doc(sessionId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data();
      if (data == null || data['status'] != 'waiting' || data['isPrivate'] != true) {
        throw StateError('Only a waiting private lobby can be configured');
      }
      if ((data['playerUids'] as List).length > maxPlayers) {
        throw StateError('Max players is below the current player count');
      }
      tx.update(ref, {
        'questionTimeLimit': questionTimeLimit,
        'maxPlayers': maxPlayers,
        'categoryId': categoryId,
        'difficulty': difficulty.name,
        'settingsVersion': (data['settingsVersion'] as int? ?? 0) + 1,
        'questionIds': <String>[],
      });
    });
  }

  static OnlineGameOptions _readOptions(Map<String, dynamic> data) {
    final difficulty = data['difficulty'] as String? ?? 'medium';
    return OnlineGameOptions(
      categoryId: data['categoryId'] as String,
      maxPlayers: data['maxPlayers'] as int,
      questionTimeLimit: data['questionTimeLimit'] as int,
      difficulty: Difficulty.values.firstWhere((d) => d.name == difficulty),
    );
  }

  static void _validateQuestionIds(OnlineGameOptions settings, List<String> ids) {
    if (ids.length < settings.requiredQuestionCount ||
        ids.toSet().length != ids.length || ids.any((id) => id.isEmpty)) {
      throw StateError('Not enough unique questions for the selected settings');
    }
  }

  // ── Leave active game ──────────────────────────────────────────────────────

  Future<void> leaveGame({
    required String sessionId,
    required String uid,
  }) async {
    final sessionRef = _sessions.doc(sessionId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(sessionRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      if (data['status'] != 'inProgress') return;

      final playerUids =
      List<String>.from(data['playerUids'] as List? ?? []);
      playerUids.remove(uid);

      if (playerUids.isEmpty) {
        tx.delete(sessionRef);
      } else {
        final currentRound = data['currentQuestionIndex'] as int? ?? 0;
        tx.update(sessionRef, {
          'playerUids': FieldValue.arrayRemove([uid]),
          'players.$uid.isEliminated': true,
          'players.$uid.eliminationRound': currentRound,
          'players.$uid.voluntaryExit': true,
          'activePlayerCount': FieldValue.increment(-1),
        });
      }
    });
  }

  // ── Join ───────────────────────────────────────────────────────────────────

  /// Adds [uid] to a waiting session.
  ///
  /// For public sessions: auto-starts when [maxPlayers] is reached.
  /// For private sessions: never auto-starts — the host calls [startSession].
  ///
  /// Throws [StateError] on concurrent conflicts; callers may retry.
  Future<String> joinSession({
    required String sessionId,
    required String uid,
    required String username,
  }) async {
    final sessionRef = _sessions.doc(sessionId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(sessionRef);
      if (!snap.exists) throw StateError('Session $sessionId not found');

      final data = snap.data()!;
      if (data['status'] != 'waiting') {
        throw StateError('Session $sessionId is no longer accepting players');
      }

      final currentUids =
      List<String>.from(data['playerUids'] as List? ?? []);
      if (currentUids.contains(uid)) return; // idempotency guard

      final maxPlayers = data['maxPlayers'] as int? ?? 0;
      if (currentUids.length >= maxPlayers) {
        throw StateError('Session $sessionId is full');
      }

      final newUids = [...currentUids, uid];
      final isNowFull = newUids.length >= maxPlayers;
      final isPrivate = data['isPrivate'] == true;
      final String profilePicture = await _getProfilePicture();

      final updates = <String, dynamic>{
        'playerUids': newUids,
        'activePlayerCount': newUids.length,
        'players.$uid': _newPlayerEntry(username, profilePicture),
      };

      // Private sessions are started manually by the host via startSession().
      if (isNowFull && !isPrivate) {
        final settings = _readOptions(data);
        settings.validate();
        _validateQuestionIds(settings, List<String>.from(data['questionIds'] as List));
        updates['status'] = 'inProgress';
        updates['gameStartTime'] = FieldValue.serverTimestamp();

        tx.set(
          sessionRef.collection('roundCounters').doc('0'),
          {
            'validatedCount': 0,
            'targetCount': newUids.length,
            'incorrectUids': <String>[],
            'validatedUids': <String>[],
            'resolved': false,
          },
        );
      }

      tx.update(sessionRef, updates);
    });

    return sessionId;
  }

  Future<void> removePlayer({
    required String sessionId,
    required String uid,
  }) async {
    final sessionRef = _sessions.doc(sessionId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(sessionRef);
      if (!snap.exists) return;

      final data = snap.data()!;
      if (data['status'] != 'waiting') return;

      final playerUids =
      List<String>.from(data['playerUids'] as List? ?? []);
      playerUids.remove(uid);

      if (playerUids.isEmpty) {
        tx.delete(sessionRef);
      } else {
        tx.update(sessionRef, {
          'playerUids': FieldValue.arrayRemove([uid]),
          'players.$uid': FieldValue.delete(),
          'activePlayerCount': playerUids.length,
        });
      }
    });
  }

  // ── Stream ─────────────────────────────────────────────────────────────────

  Stream<Map<String, dynamic>> sessionDocStream(String sessionId) {
    return _sessions.doc(sessionId).snapshots().map((snap) {
      if (!snap.exists) throw StateError('Session $sessionId not found');
      return snap.data()!;
    });
  }

  // ── Answer submission ──────────────────────────────────────────────────────

  Future<void> submitAnswer({
    required String sessionId,
    required String uid,
    required int roundIndex,
    required String questionId,
    required String answer,
  }) async {
    await _sessions
        .doc(sessionId)
        .collection('answers')
        .doc('${uid}_$roundIndex')
        .set({
      'uid': uid,
      'roundIndex': roundIndex,
      'questionId': questionId,
      'answer': answer,
      'answeredAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Archive ────────────────────────────────────────────────────────────────

  Future<MultiplayerSessionData> fetchArchivedSession(String sessionId) async {
    final snap = await _archive.doc(sessionId).get();
    if (!snap.exists) {
      throw StateError('Archived session $sessionId not found');
    }
    return MultiplayerSessionData.fromJson(snap.data()!);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _newPlayerEntry(
      String username,
      String profilePicture,
      ) =>
      {
        'username': username,
        'isEliminated': false,
        'profilePicture': profilePicture,
        'lotteryTickets': 0,
        'correctAnswers': 0,
        'totalAnswers': 0,
      };

  Future<String> _getProfilePicture() async {
    final ProfileData? data = await _profileRepo.getProfileData();
    return data?.profilePicture ?? 'deafultAvatar.png';
  }
}
