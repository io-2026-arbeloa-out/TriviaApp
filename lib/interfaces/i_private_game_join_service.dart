import 'package:triviaapp/models/session_data.dart';

abstract class IPrivateGameJoinService {
  Future<SessionData> joinPrivateGame(int code);

  Future<void> leaveGame(String sessionId, String playerId);

  Stream<SessionData> listenToLobby(String sessionId);

  void ready();
}