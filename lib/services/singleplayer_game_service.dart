import 'package:triviaapp/interfaces/i_singleplayer_game_service.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';

class SingleplayerGameService implements ISingleplayerGameService {
  final FirebaseQuestionRepository _questionRepository;

  SingleplayerGameService({FirebaseQuestionRepository? questionRepository})
      : _questionRepository =
      questionRepository ?? FirebaseQuestionRepository();

  @override
  Future<List<Question>> loadQuestions(
      SingleplayerGameOptions options,
      String category,
      ) {
    return _questionRepository.getQuestions(
      limit: options.numQuestions,
      category: category,
      questionTypes: options.gameQuestionType.toQuestionTypes(),
    );
  }

  @override
  bool checkAnswer(Question question, String answer) {
    final normalised = answer.trim().toLowerCase();
    return question.correctAnswers.any(
          (correct) => correct.trim().toLowerCase() == normalised,
    );
  }
}