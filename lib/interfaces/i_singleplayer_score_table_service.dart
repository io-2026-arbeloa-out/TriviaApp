import 'package:triviaapp/models/session_data.dart';

abstract class ISingleplayerScoreTableService {
  Future<SessionData> getGameData(String sessionId);
}