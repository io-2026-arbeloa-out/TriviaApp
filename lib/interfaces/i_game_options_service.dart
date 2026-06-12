import 'package:triviaapp/models/online_game_options.dart';

abstract class IGameOptionsService {
  Future<void> saveOptions(OnlineGameOptions options);

  Future<OnlineGameOptions> getOptions();
}