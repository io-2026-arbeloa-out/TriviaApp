abstract class IMultiplayerConnectionService {
  /// Finds an existing waiting session for [categoryId]/[maxPlayers] or
  /// creates a new one (including fetching questions). Returns the sessionId.
  Future<String> connectPlayer({
    required String uid,
    required String username,
    required String categoryId,
    required int maxPlayers,
  });

  /// Removes the player from a waiting session.
  /// If the player was the last one, the session document is deleted.
  /// No-op if the session is already inProgress or finished.
  Future<void> disconnectPlayer({
    required String sessionId,
    required String uid,
  });
}