import 'package:triviaapp/models/game_question_type.dart';

class SingleplayerGameOptions {
  final int _numQuestions;
  final int _timePerQuestion; // in seconds; 0 = brak limitu
  final GameQuestionType _gameQuestionType;

  const SingleplayerGameOptions({
    int numQuestions = 10,
    int timePerQuestion = 0,
    GameQuestionType gameQuestionType = GameQuestionType.mixed,
  }) : _numQuestions = numQuestions,
       _gameQuestionType = gameQuestionType,
       _timePerQuestion = timePerQuestion;

  SingleplayerGameOptions copyWith({
    int? numQuestions,
    int? timePerQuestion,
    GameQuestionType? gameQuestionType,
  }) {
    return SingleplayerGameOptions(
      numQuestions: numQuestions ?? this.numQuestions,
      timePerQuestion: timePerQuestion ?? this.timePerQuestion,
      gameQuestionType: gameQuestionType ?? this.gameQuestionType,
    );
  }

  int get numQuestions => _numQuestions;
  int get timePerQuestion => _timePerQuestion;
  GameQuestionType get gameQuestionType => _gameQuestionType;
}