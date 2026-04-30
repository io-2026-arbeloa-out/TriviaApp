import 'package:triviaapp/interfaces/i_multiplayer_game_service.dart';
import 'package:triviaapp/models/player.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

class MultiplayerGameService implements IMultiplayerGameService {
  final FirebaseSessionRepository _sessionRepository;
  final FirebaseQuestionRepository _questionRepository;

  MultiplayerGameService(
      this._sessionRepository,
      this._questionRepository,
      );

  @override
  Future<void> registerAnswer(
      Player player,
      Question question,
      String answer,
      ) async {
    final isCorrect = checkAnswer(question, answer);
    // Tutaj przykładowo aktualizujemy wynik w sesji.
    // Wymaga konkretnej metody w repo (updatePlayerScore).
    if (isCorrect) {
      await _sessionRepository.updatePlayerScore(
        question.id, // tu raczej sessionId – dostosuj do swojego API
        player.username,
        1, // przyrost punktów
      );
    }
  }

  @override
  bool checkAnswer(Question question, String answer) {
    return question.correctAnswers.contains(answer);
  }

  @override
  Future<void> endGame(MultiplayerSessionData session) {
    return _sessionRepository.updateSessionStatus(
      session.sessionId,
      'FINISHED',
    );
  }

  @override
  Stream<MultiplayerSessionData> listenToSession(String sessionId) {
    return _sessionRepository
        .getSessionStream(sessionId)
        .cast<MultiplayerSessionData>(); // dostosuj typowanie do swojego repo
  }
}