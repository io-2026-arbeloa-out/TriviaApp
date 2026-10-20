enum QuestionType {
  trueFalse,
  open4,
  open6,
  open,
  mixed;

  // Preserve the Firebase/callable representation independently of Dart names.
  String toJson() => this == trueFalse ? 'true_false' : name;

  static QuestionType fromJson(String? json) {
    if (json == null) return QuestionType.mixed; // wartość domyślna

    return QuestionType.values.firstWhere(
      (type) => type.toJson() == json,
      orElse: () => QuestionType.mixed, // wartość domyślna gdy nie znaleziono
    );
  }

  List<QuestionType> toList() {
    switch (this) {
      case QuestionType.trueFalse:
        return [QuestionType.trueFalse];
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
