import 'package:triviaapp/models/session_snapshot.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/game_answer.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/online_game_options.dart';

abstract class SessionRepository {
  Stream<SessionSnapshot> sessionDocStream(String sessionId);
  Future<String?> findWaitingSession({
    required String categoryId,
    required int maxPlayers,
  });
  Future<String?> findPrivateSession({required int entryCode});
  Future<String> createSession({required OnlineGameOptions settings});
  Future<String> joinSession({required String sessionId, int? entryCode});
  Future<void> startSession({required String sessionId});
  Future<void> updateSessionSettings({
    required String sessionId,
    required int questionTimeLimit,
    required int maxPlayers,
    required String categoryId,
    required Difficulty difficulty,
  });
  Future<void> leaveGame({required String sessionId, required String uid});
  Future<void> removePlayer({required String sessionId, required String uid});
  Future<GameAnswer> submitAnswer({
    required String sessionId,
    required String uid,
    required int roundIndex,
    required String questionId,
    required String answer,
  });
  Future<MultiplayerSessionData> fetchArchivedSession(String sessionId);
}
