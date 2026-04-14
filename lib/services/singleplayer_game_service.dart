import 'package:triviaapp/interfaces/i_singleplayer_game_service.dart';
import 'package:triviaapp/models/private_game_options.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/session_data.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

class SingleplayerGameService implements ISingleplayerGameService {
  final FirebaseSessionRepository _sessionRepository;
  final FirebaseQuestionRepository _questionRepository;

  SingleplayerGameService(
      this._sessionRepository,
      this._questionRepository,
      );

  @override
  Future<SessionData> startGame(PrivateGameOptions options) async {
    throw UnimplementedError();
  }

  @override
  Future<void> registerAnswer(Question question, String answer) async {
    // W singleplayer możesz tu np. lokalnie zapisywać odpowiedzi
    // lub aktualizować wynik w sesji.
    // To wymaga rozszerzenia FirebaseSessionRepository.
    // Na razie pozostawiam jako no-op.
  }

  @override
  bool checkAnswer(Question question, String answer) {
    return question.correctAnswers.contains(answer);
  }

  @override
  Future<void> endGame(SessionData session) async {
    await _sessionRepository.updateSessionStatus(session.sessionId, 'FINISHED');
  }
}