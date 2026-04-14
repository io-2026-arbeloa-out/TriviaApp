import 'package:triviaapp/models/private_game_options.dart';
import 'package:triviaapp/models/session_data.dart';

abstract class IPrivateGameCreationService {
  Future<SessionData> createPrivateGame(PrivateGameOptions options);

  Future<void> deleteGame(String sessionId);

  Future<void> startGame(String sessionId);
}