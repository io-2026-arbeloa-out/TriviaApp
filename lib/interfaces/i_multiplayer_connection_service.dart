abstract class IMultiplayerConnectionService {
  void connectPlayer();

  Future<void> connectPlayers();

  Future<void> startMultiplayerGame();
}