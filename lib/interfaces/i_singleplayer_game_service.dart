import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/game_answer.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';

abstract class ISingleplayerGameService {
  Future<List<Question>> loadQuestions(
      SingleplayerGameOptions options,
      String category,
      );

  List<String> getAnswerOptions(Question question);

  Future<GameAnswer> checkAnswer(Question question, String answer);
}
