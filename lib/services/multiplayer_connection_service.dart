import 'package:triviaapp/interfaces/i_multiplayer_connection_service.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

class MultiplayerConnectionService implements IMultiplayerConnectionService {
  final FirebaseSessionRepository _sessionRepository;
  final FirebaseQuestionRepository _questionRepository;

  static const int _questionsPerGame = 10;

  MultiplayerConnectionService({
    required FirebaseSessionRepository sessionRepository,
    required FirebaseQuestionRepository questionRepository,
  })  : _sessionRepository = sessionRepository,
        _questionRepository = questionRepository;

  @override
  Future<String> connectPlayer({
    required String uid,
    required String username,
    required String categoryId,
    required int maxPlayers,
  }) async {
    final existingId = await _sessionRepository.findWaitingSession(
      categoryId: categoryId,
      maxPlayers: maxPlayers,
    );

    if (existingId != null) {
      return _sessionRepository.joinSession(
        sessionId: existingId,
        uid: uid,
        username: username,
      );
    }

    final questions = await _questionRepository.getQuestions(
      limit: _questionsPerGame,
      category: categoryId,
      questionTypes: QuestionType.values,
    );

    if (questions.isEmpty) {
      throw StateError('No questions available for category "$categoryId"');
    }

    questions.shuffle();//todo check

    return _sessionRepository.createSession(
      categoryId: categoryId,
      maxPlayers: maxPlayers,
      questionIds: questions.map((q) => q.id).toList(),
      uid: uid,
      username: username,
    );
  }

  @override
  Future<void> disconnectPlayer({
    required String sessionId,
    required String uid,
  }) {
    return _sessionRepository.removePlayer(
      sessionId: sessionId,
      uid: uid,
    );
  }
}