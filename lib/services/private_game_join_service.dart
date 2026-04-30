import 'package:triviaapp/interfaces/i_private_game_join_service.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

class PrivateGameJoinService implements IPrivateGameJoinService {
  final FirebaseSessionRepository _sessionRepository;

  PrivateGameJoinService(this._sessionRepository);

  @override
  Future<MultiplayerSessionData> joinPrivateGame(int code) {
    // Wymaga metody wyszukującej sesję po kodzie w repo.
    // Na razie traktujemy code jako sessionId-string.
    return _sessionRepository.joinMultiplayerSession(code.toString(), 'player');
  }

  @override
  Future<void> leaveGame(String sessionId, String playerId) async {
    // Wymaga logiki usuwania gracza z sesji.
    throw UnimplementedError('leaveGame wymaga dodatkowej logiki w repo');
  }

  @override
  Stream<MultiplayerSessionData> listenToLobby(String sessionId) {
    return _sessionRepository
        .getSessionStream(sessionId)
        .cast<MultiplayerSessionData>(); // dopasuj typ
  }

  @override
  void ready() {
    // Możesz tu np. ustawiać flagę „ready” w session/player w repo.
    // Placeholder.
  }
}