import 'package:triviaapp/models/online_game_options.dart';

abstract class IMultiplayerConnectionService {
  Future<String> connectPlayer({
    required String uid,
    required String username,
    required OnlineGameOptions settings,
  });

  Future<void> disconnectPlayer({
    required String sessionId,
    required String uid,
  });
}