import 'package:triviaapp/models/question_type.dart';

enum GameQuestionType {
  boolean,
  open,
  closed4,
  closed6,
  mixed;

  static GameQuestionType fromJson(String? json) {
    if (json == null) return GameQuestionType.open; // wartość domyślna

    return GameQuestionType.values.firstWhere(
          (type) => type.name == json,
      orElse: () => GameQuestionType.open, // wartość domyślna gdy nie znaleziono
    );
  }

  List<QuestionType> toQuestionTypes() {
    switch (this) {
      case GameQuestionType.boolean:
        return [QuestionType.boolean];
      case GameQuestionType.open:
        return [QuestionType.open4, QuestionType.open6];
      case GameQuestionType.closed4:
        return [QuestionType.open4];
      case GameQuestionType.closed6:
        return [QuestionType.open6];
      case GameQuestionType.mixed:
        return QuestionType.values;
    }
  }
}