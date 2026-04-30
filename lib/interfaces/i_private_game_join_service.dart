import 'package:triviaapp/models/multiplayer_session_data.dart';

abstract class IPrivateGameJoinService {
  Future<MultiplayerSessionData> joinPrivateGame(int code);

  Future<void> leaveGame(String sessionId, String playerId);

  Stream<MultiplayerSessionData> listenToLobby(String sessionId);

  void ready();
}