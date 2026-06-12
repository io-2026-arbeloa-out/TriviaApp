/*
import 'package:triviaapp/interfaces/i_private_game_creation_service.dart';
import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

class PrivateGameCreationService implements IPrivateGameCreationService {
  final FirebaseSessionRepository _sessionRepository;

  PrivateGameCreationService(this._sessionRepository);

  @override
  Future<MultiplayerSessionData> createPrivateGame(PrivateGameOptions options) {
    // Użyj createMultiplayerSession z kodem / kategorią z options
    return _sessionRepository.createMultiplayerSession(
      options.quizId,
      'host',
    );
  }

  @override
  Future<void> deleteGame(String sessionId) {
    // W diagramie nie ma metody delete w repo – wymaga dodania.
    throw UnimplementedError('deleteGame wymaga metody w FirebaseSessionRepository');
  }

  @override
  Future<void> startGame(String sessionId) {
    return _sessionRepository.updateSessionStatus(sessionId, 'IN_PROGRESS');
  }
}*/
