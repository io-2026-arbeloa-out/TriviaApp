import 'package:triviaapp/interfaces/i_singleplayer_game_service.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/session_data.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';
import 'package:triviaapp/services/question_service.dart';

class SingleplayerGameService implements ISingleplayerGameService {
  final FirebaseSessionRepository _sessionRepository;
  final String _category;
  final QuestionService _questionService;

  SingleplayerGameService({
    required String category,
    FirebaseSessionRepository? sessionRepository,
    QuestionService? questionService,
  }) :  _category = category,
        _sessionRepository = sessionRepository ?? FirebaseSessionRepository(),
        _questionService = questionService ?? QuestionService();

  @override
  String get category => _category;
  QuestionService get questionService => _questionService;
  FirebaseSessionRepository get sessionRepository => _sessionRepository;

  @override
  Future<SessionData> startGame() async {
    // TODO: Implementacja rozpoczęcia gry
    throw UnimplementedError();
  }

  @override
  Future<void> registerAnswer(String answer) async {
    // TODO: W singleplayer możesz tu np. lokalnie zapisywać odpowiedzi
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

  @override
  Future<List<Question>> getQuestions(int number, String quizId) async {
    return _questionService.getQuestions(number, quizId);
  }

  @override
  Future<String> getQuestionText() async {
    // TODO: Implementacja pobierania tekstu aktualnego pytania
    throw UnimplementedError();
  }
}