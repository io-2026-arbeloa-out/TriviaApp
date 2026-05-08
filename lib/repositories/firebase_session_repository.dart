import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';

class FirebaseSessionRepository {
  final FirebaseFirestore _firestore;

  FirebaseSessionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _sessions =>
      _firestore.collection('sessions');

  CollectionReference<Map<String, dynamic>> get _archive =>
      _firestore.collection('sessions_archive');

  // ── Matchmaking ────────────────────────────────────────────────────────────

  /// Returns the sessionId of a waiting session for this category/size,
  /// or null if none exists yet.
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

  /// Creates a new session document + adds the first player to the players
  /// subcollection. Returns the new sessionId.
  Future<String> createSession({
    required String categoryId,
    required int maxPlayers,
    required List<String> questionIds,
    required String uid,
    required String username,
  }) async {
    final docRef = _sessions.doc();

    await _firestore.runTransaction((tx) async {
      // Main session document
      tx.set(docRef, {
        'status': 'waiting',
        'categoryId': categoryId,
        'maxPlayers': maxPlayers,
        'questionIds': questionIds,
        'playerUids': [uid],
        'currentQuestionIndex': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'gameStartTime': null,
        'endTime': null,
      });

      // First player document in subcollection
      tx.set(docRef.collection('players').doc(uid), {
        'uid': uid,
        'username': username,
        'joinedAt': FieldValue.serverTimestamp(),
        'isEliminated': false,
        'eliminationRound': null,
        'lotteryTickets': 0,
      });
    });

    return docRef.id;
  }

  /// Adds a player to an existing session. Returns the sessionId.
  /// The Cloud Function [onPlayerJoin] starts the game when maxPlayers is
  /// reached.
  Future<String> joinSession({
    required String sessionId,
    required String uid,
    required String username,
  }) async {
    final sessionRef = _sessions.doc(sessionId);

    await _firestore.runTransaction((tx) async {
      tx.update(sessionRef, {
        'playerUids': FieldValue.arrayUnion([uid]),
      });

      tx.set(sessionRef.collection('players').doc(uid), {
        'uid': uid,
        'username': username,
        'joinedAt': FieldValue.serverTimestamp(),
        'isEliminated': false,
        'eliminationRound': null,
        'lotteryTickets': 0,
      });
    });

    return sessionId;
  }

  // ── Streams ────────────────────────────────────────────────────────────────

  /// Main session document stream (status, currentQuestionIndex, etc.).
  Stream<Map<String, dynamic>> sessionDocStream(String sessionId) {
    return _sessions.doc(sessionId).snapshots().map((snap) {
      if (!snap.exists) throw StateError('Session $sessionId not found');
      return snap.data()!;
    });
  }

  /// Stream of all player documents in the session's subcollection.
  Stream<List<Map<String, dynamic>>> playersStream(String sessionId) {
    return _sessions
        .doc(sessionId)
        .collection('players')
        .snapshots()
        .map((snap) => snap.docs.map((d) => d.data()).toList());
  }

  /// Stream for a specific round document. Emits null if the round doc
  /// does not exist yet (CF hasn't created it).
  Stream<Map<String, dynamic>?> roundStream(
      String sessionId, int roundIndex) {
    return _sessions
        .doc(sessionId)
        .collection('rounds')
        .doc(roundIndex.toString())
        .snapshots()
        .map((snap) => snap.exists ? snap.data() : null);
  }

  /// Stream of the answer documents for a given round. Provides both count
  /// and the set of UIDs who have already answered.
  Stream<({int count, Set<String> answeredUids})> answersStream(
      String sessionId, int roundIndex) {
    return _sessions
        .doc(sessionId)
        .collection('answers')
        .where('roundIndex', isEqualTo: roundIndex)
        .snapshots()
        .map((snap) => (
    count: snap.size,
    answeredUids:
    snap.docs.map((d) => d.data()['uid'] as String).toSet(),
    ));
  }

  // ── Actions ────────────────────────────────────────────────────────────────

  /// Writes a player's answer. Does NOT include [isCorrect] — the Cloud
  /// Function [onAnswerSubmit] validates and sets that field server-side.
  Future<void> submitAnswer({
    required String sessionId,
    required String uid,
    required int roundIndex,
    required String questionId,
    required String answer,
  }) async {
    // Document ID enforced by Firestore rules: must be uid_roundIndex
    final docId = '${uid}_$roundIndex';

    await _sessions
        .doc(sessionId)
        .collection('answers')
        .doc(docId)
        .set({
      'uid': uid,
      'roundIndex': roundIndex,
      'questionId': questionId,
      'answer': answer,
      'answeredAt': FieldValue.serverTimestamp(),
      // isCorrect intentionally omitted — set by Cloud Function
    });
  }

  // ── Archive ────────────────────────────────────────────────────────────────

  /// Fetches the final [MultiplayerSessionData] from [sessions_archive],
  /// written by the [onGameFinished] Cloud Function.
  Future<MultiplayerSessionData> fetchArchivedSession(
      String sessionId) async {
    final snap = await _archive.doc(sessionId).get();
    if (!snap.exists) {
      throw StateError('Archived session $sessionId not found');
    }
    return MultiplayerSessionData.fromJson(snap.data()!);
  }
}