import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/session_data.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';

abstract class ISingleplayerGameService {
  Future<List<Question>> loadQuestions(
      SingleplayerGameOptions options,
      String category,
      );

  bool checkAnswer(Question question, String answer);
}