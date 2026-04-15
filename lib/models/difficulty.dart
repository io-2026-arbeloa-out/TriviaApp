enum Difficulty{
  easy,
  medium,
  hard,
  impossible;

  static Difficulty fromJson(String? json) {
    if (json == null) return Difficulty.medium; // wartość domyślna

    return Difficulty.values.firstWhere(
          (difficulty) => difficulty.name == json,
      orElse: () => Difficulty.medium, // wartość domyślna gdy nie znaleziono
    );
  }
}