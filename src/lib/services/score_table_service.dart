import 'package:triviaapp/interfaces/i_score_table_service.dart';
import 'package:triviaapp/models/session_data.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

class ScoreTableService implements IScoreTableService {
  final FirebaseSessionRepository _sessionRepository;

  ScoreTableService(this._sessionRepository);

  @override
  Future<SessionData> getGameData(String sessionId) {
    return _sessionRepository.getGameData(sessionId);
  }
}