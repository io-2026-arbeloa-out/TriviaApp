import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/session_data.dart';

abstract class ISingleplayerGameService {
  Future<SessionData> startGame();

  Future<void> registerAnswer(Question question, String answer);

  bool checkAnswer(Question question, String answer);

  Future<void> endGame(SessionData session);
}