import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triviaapp/models/game_mode.dart';
import 'package:triviaapp/models/player.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/session_status.dart';

class FirebaseSessionRepository {
  final FirebaseFirestore _firestore;

  FirebaseSessionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Tworzy nową sesję multiplayer.
  /// Zakładam kolekcję 'sessions'.
  Future<MultiplayerSessionData> createMultiplayerSession(
      String categoryId,
      String playerName,
      ) async {
    final docRef = _firestore.collection('sessions').doc();

    final session = MultiplayerSessionData(
      sessionId: docRef.id,
      numPlayers: 1,
      status: SessionStatus.inProgress,
      sessionStartTime: DateTime.now(),
      gameStartTime: DateTime.now(),
      endTime: DateTime.now(),
      players: [
        Player(uid: docRef.id, username: playerName),
      ],
      placement: [],
      questions: [],
      gameMode: GameMode.singleplayer,
    );

    await docRef.set(_toJson(session, categoryId: categoryId));
    return session;
  }

  Future<MultiplayerSessionData> joinMultiplayerSession(
      String sessionId,
      String playerName,
      ) async {
    final docRef = _firestore.collection('sessions').doc(sessionId);
    final snap = await docRef.get();
    if (!snap.exists) {
      throw StateError('Session not found: $sessionId');
    }

    final data = snap.data()!;
    final session = MultiplayerSessionData.fromJson(data);

    final updatedPlayers = [
      ...session.players,
      Player(uid: '${session.players.length + 1}', username: playerName),
    ];

    await docRef.update({
      'numPlayers': updatedPlayers.length,
      'players': updatedPlayers.map((p) => {
        'uid': p.uid,
        'username': p.username,
      }),
    });

    final updatedSession = MultiplayerSessionData(
      sessionId: session.sessionId,
      numPlayers: updatedPlayers.length,
      status: session.status,
      sessionStartTime: session.sessionStartTime,
      gameStartTime: session.gameStartTime,
      endTime: session.endTime,
      players: updatedPlayers,
      placement: session.placement,
      questions: session.questions,
      gameMode: session.gameMode,
    );

    return updatedSession;
  }

  Stream<MultiplayerSessionData> getSessionStream(String sessionId) {
    return _firestore
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .map((snap) => MultiplayerSessionData.fromJson(snap.data()!));
  }

  Future<void> updatePlayerScore(
      String sessionId,
      String playerName,
      int score,
      ) async {
    // Zakładamy, że trzymasz scoreboard np. w mapie {playerName: score}.
    final docRef = _firestore.collection('sessions').doc(sessionId);
    await docRef.update({
      'scores.$playerName': FieldValue.increment(score),
    });
  }

  Future<void> updateSessionStatus(String sessionId, String status) async {
    final docRef = _firestore.collection('sessions').doc(sessionId);
    await docRef.update({'status': status});
  }

  /// Opcjonalna pomocnicza metoda dla ScoreTableService.
  Future<MultiplayerSessionData> getGameData(String sessionId) async {
    final snap =
    await _firestore.collection('sessions').doc(sessionId).get();
    if (!snap.exists) {
      throw StateError('Session not found: $sessionId');
    }
    return MultiplayerSessionData.fromJson(snap.data()!);
  }

  Map<String, dynamic> _toJson(
      MultiplayerSessionData session, {
        required String categoryId,
      }) {
    return {
      'sessionId': session.sessionId,
      'numPlayers': session.numPlayers,
      'status': session.status.name,
      'sessionStartTime': session.sessionStartTime.toIso8601String(),
      'gameStartTime': session.gameStartTime.toIso8601String(),
      'endTime': session.endTime?.toIso8601String(),
      'players': session.players
          .map((p) => {
        'uid': p.uid,
        'username': p.username,
      })
          .toList(),
      'placement': session.placement,
      'questions': session.questions.map((q) => q.toJson()).toList(),
      'categoryId': categoryId,
    };
  }
}