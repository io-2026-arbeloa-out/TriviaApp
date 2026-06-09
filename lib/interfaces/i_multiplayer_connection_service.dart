abstract class IMultiplayerConnectionService {
  Future<String> connectPlayer({
    required String uid,
    required String username,
    required String categoryId,
    required int maxPlayers,
  });

  Future<void> disconnectPlayer({
    required String sessionId,
    required String uid,
  });
}