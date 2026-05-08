abstract class IMultiplayerConnectionService {
  /// Finds an existing waiting session for [categoryId]/[maxPlayers] or
  /// creates a new one (including fetching questions). Returns the sessionId.
  Future<String> connectPlayer({
    required String uid,
    required String username,
    required String categoryId,
    required int maxPlayers,
  });
}