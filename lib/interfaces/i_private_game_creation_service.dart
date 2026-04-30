import 'package:triviaapp/models/private_game_options.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';

abstract class IPrivateGameCreationService {
  Future<MultiplayerSessionData> createPrivateGame(PrivateGameOptions options);

  Future<void> deleteGame(String sessionId);

  Future<void> startGame(String sessionId);
}