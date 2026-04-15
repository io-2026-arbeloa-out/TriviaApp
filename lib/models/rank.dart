enum Rank{
  unranked,
  bronze,
  silver,
  gold,
  diamond,
  master,
  champion;

  static Rank fromJson(String? json) {
    if (json == null) return Rank.unranked; // wartość domyślna

    return Rank.values.firstWhere(
          (type) => type.name == json,
      orElse: () => Rank.unranked, // wartość domyślna gdy nie znaleziono
    );
  }
}