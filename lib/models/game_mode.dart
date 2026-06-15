enum GameMode {
  ranked,
  private,
  singleplayer,
  casual;

  static GameMode fromJson(String? json) {
    if (json == null) return GameMode.singleplayer; // wartość domyślna

    return GameMode.values.firstWhere(
          (type) => type.name == json,
      orElse: () => GameMode.singleplayer, // wartość domyślna gdy nie znaleziono
    );
  }
}