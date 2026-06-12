import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';

abstract class IPrivateGameCreationService {
  Future<MultiplayerSessionData> createPrivateGame(OnlineGameOptions options);

  Future<void> deleteGame(String sessionId);

  Future<void> startGame(String sessionId);
}