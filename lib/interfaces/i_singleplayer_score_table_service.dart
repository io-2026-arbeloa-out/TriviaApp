import 'package:triviaapp/models/multiplayer_session_data.dart';

abstract class ISingleplayerScoreTableService {
  Future<MultiplayerSessionData> getGameData(String sessionId);
}