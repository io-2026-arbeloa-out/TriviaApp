import 'package:triviaapp/models/question_type.dart';

class SingleplayerGameOptions {
  final int _numQuestions;
  final int _timePerQuestion; // in seconds; 0 = brak limitu
  final QuestionType _questionType;

  const SingleplayerGameOptions({
    int numQuestions = 10,
    int timePerQuestion = 0,
    QuestionType questionType = QuestionType.mixed,
  }) : _numQuestions = numQuestions,
       _questionType = questionType,
       _timePerQuestion = timePerQuestion;

  SingleplayerGameOptions copyWith({
    int? numQuestions,
    int? timePerQuestion,
    QuestionType? questionType,
  }) {
    return SingleplayerGameOptions(
      numQuestions: numQuestions ?? this.numQuestions,
      timePerQuestion: timePerQuestion ?? this.timePerQuestion,
      questionType: questionType ?? this.questionType,
    );
  }

  int get numQuestions => _numQuestions;
  int get timePerQuestion => _timePerQuestion;
  QuestionType get questionType => _questionType;
}