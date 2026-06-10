import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';

class FirebaseSessionRepository {
  final FirebaseFirestore _firestore;
  final FirebaseProfileRepository _profileRepo;

  FirebaseSessionRepository({
    FirebaseFirestore? firestore,
    FirebaseProfileRepository? profileRepo
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _profileRepo = profileRepo ?? FirebaseProfileRepository();

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('sessions');

  CollectionReference<Map<String, dynamic>> get _archive =>
      _firestore.collection('sessions_archive');

  // ── Matchmaking ────────────────────────────────────────────────────────────

  Future<String?> findWaitingSession({
    required String categoryId,
    required int maxPlayers,
  }) async {
    final snap = await _sessions
        .where('status', isEqualTo: 'waiting')
        .where('categoryId', isEqualTo: categoryId)
        .where('maxPlayers', isEqualTo: maxPlayers)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  Future<String> createSession({
    required String categoryId,
    required int maxPlayers,
    required List<String> questionIds,
    required String uid,
    required String username,
  }) async {
    final docRef = _sessions.doc();
    final String profilePicture = await _getProfilePicture();

    await docRef.set({
      'status': 'waiting',
      'phase': 'answering',
      'categoryId': categoryId,
      'maxPlayers': maxPlayers,
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

  // ── Leave active game ──────────────────────────────────────────────────────

  /// Removes [uid] from an active session.
  /// Deletes the session document when the last player leaves.
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
        // FIX: zamiast kasowac dane gracza, oznaczamy go jako wyeliminowanego.
        // buildArchive w CF uwzgledni go w tabeli wynikow.
        final currentRound = data['currentQuestionIndex'] as int? ?? 0;
        tx.update(sessionRef, {
          'playerUids': FieldValue.arrayRemove([uid]),
          'players.$uid.isEliminated': true,
          'players.$uid.eliminationRound': currentRound,
          'activePlayerCount': FieldValue.increment(-1),
        });
      }
    });
  }

  /// Adds a player and — if the session is now full — atomically flips
  /// [status] to [inProgress] and creates [roundCounters/0].
  /// No Cloud Function is required for game start.
  ///
  /// Throws [StateError] when the session was taken by another player
  /// concurrently; the caller should surface this as a matchmaking retry.
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
      final String profilePicture = await _getProfilePicture();

      final updates = <String, dynamic>{
        'playerUids': newUids,
        'activePlayerCount': newUids.length,
        'players.$uid': _newPlayerEntry(username, profilePicture),
      };

      if (isNowFull) {
        updates['status'] = 'inProgress';
        updates['gameStartTime'] = FieldValue.serverTimestamp();

        // Create the first round counter in the same transaction so that a
        // fast player cannot submit an answer before targetCount is set.
        tx.set(
          sessionRef.collection('roundCounters').doc('0'),
          {
            'validatedCount': 0,
            'targetCount': newUids.length,
            'incorrectUids': <String>[],
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

  static Map<String, dynamic> _newPlayerEntry(String username, String profilePicture) => {
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