import 'package:triviaapp/models/player.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';

abstract class IMultiplayerGameService {
  Future<void> registerAnswer(
      Player player,
      Question question,
      String answer,
      );

  bool checkAnswer(Question question, String answer);

  Future<void> endGame(MultiplayerSessionData session);

  Stream<MultiplayerSessionData> listenToSession(String sessionId);
}