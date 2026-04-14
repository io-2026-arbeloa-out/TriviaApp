import 'package:triviaapp/models/session_data.dart';

abstract class IScoreTableService {
  Future<SessionData> getGameData(String sessionId);
}