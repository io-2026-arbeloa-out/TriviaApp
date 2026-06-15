import 'dart:math';

import 'package:triviaapp/interfaces/i_singleplayer_game_service.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';

class SingleplayerGameService implements ISingleplayerGameService {
  final FirebaseQuestionRepository _questionRepository;
  final Random _random;

  SingleplayerGameService({
    FirebaseQuestionRepository? questionRepository,
    Random? random,
  })  : _questionRepository =
      questionRepository ?? FirebaseQuestionRepository(),
        _random = random ?? Random();

  @override
  Future<List<Question>> loadQuestions(
      SingleplayerGameOptions options,
      String category,
      ) {
    return _questionRepository.getQuestions(
      limit: options.numQuestions,
      category: category,
      questionTypes: options.questionType.toList(),
      difficulty: Difficulty.random,
    );
  }

  @override
  List<String> getAnswerOptions(Question question) {
    if (question.type == QuestionType.true_false) {
      return ['Prawda', 'Fałsz'];
    }
    final opts = [
      ...question.correctAnswers,
      ...?question.wrongAnswers,
    ];
    opts.shuffle(_random);
    return opts;
  }

  @override
  bool checkAnswer(Question question, String answer) {
    final normalised = answer.toLowerCase();
    return question.correctAnswers.any(
          (correct) => correct.trim().toLowerCase() == normalised,
    );
  }
}