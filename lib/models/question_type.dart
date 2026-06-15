enum QuestionType {
  true_false,
  open4,
  open6,
  open,
  mixed;

  static QuestionType fromJson(String? json) {
    if (json == null) return QuestionType.mixed; // wartość domyślna

    return QuestionType.values.firstWhere(
          (type) => type.name == json,
      orElse: () => QuestionType.mixed, // wartość domyślna gdy nie znaleziono
    );
  }

  List<QuestionType> toList() {
    switch (this) {
      case QuestionType.true_false:
        return [QuestionType.true_false];
      case QuestionType.open:
        return [QuestionType.open4, QuestionType.open6];
      case QuestionType.open4:
        return [QuestionType.open4];
      case QuestionType.open6:
        return [QuestionType.open6];
      case QuestionType.mixed:
        return QuestionType.values;
    }
  }
}