enum QuestionType {
  boolean,
  open4,
  open6;

  static QuestionType fromJson(String? json) {
    if (json == null) return QuestionType.boolean; // wartość domyślna

    return QuestionType.values.firstWhere(
          (type) => type.name == json,
      orElse: () => QuestionType.boolean, // wartość domyślna gdy nie znaleziono
    );
  }
}