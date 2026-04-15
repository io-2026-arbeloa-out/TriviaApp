
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/session_data.dart';

abstract class ISingleplayerGameService {
  final String _category;

  ISingleplayerGameService({
    required String category,
  }) :  _category = category;

  Future<SessionData> startGame();

  Future<void> registerAnswer(String answer);

  bool checkAnswer(Question question, String answer);

  Future<void> endGame(SessionData session);

  Future<List<Question>> getQuestions(int number, String quizId);

  Future<String> getQuestionText();

  String get category => _category;
}