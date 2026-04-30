import 'package:triviaapp/interfaces/i_singleplayer_score_table_service.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

class SingleplayerScoreTableService implements ISingleplayerScoreTableService {
  final FirebaseSessionRepository _sessionRepository;

  SingleplayerScoreTableService(this._sessionRepository);

  @override
  Future<MultiplayerSessionData> getGameData(String sessionId) {
    return _sessionRepository.getGameData(sessionId);
  }
}