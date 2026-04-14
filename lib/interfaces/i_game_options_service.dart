import 'package:triviaapp/models/private_game_options.dart';

abstract class IGameOptionsService {
  Future<void> saveOptions(PrivateGameOptions options);

  Future<PrivateGameOptions> getOptions();
}