import 'package:triviaapp/interfaces/i_multiplayer_connection_service.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

class MultiplayerConnectionService implements IMultiplayerConnectionService {
  final FirebaseSessionRepository _sessionRepository;
  final FirebaseQuestionRepository _questionRepository;

  static const int _questionsPerGame = 10;
  static const int _maxMatchmakingAttempts = 3;

  MultiplayerConnectionService({
    FirebaseSessionRepository? sessionRepository,
    FirebaseQuestionRepository? questionRepository,
  })  : _sessionRepository = sessionRepository ?? FirebaseSessionRepository(),
        _questionRepository = questionRepository ?? FirebaseQuestionRepository();

  @override
  Future<String> connectPlayer({
    required String uid,
    required String username,
    required String categoryId,
    required int maxPlayers,
  }) async {
    Object? lastError;

    for (var attempt = 0; attempt < _maxMatchmakingAttempts; attempt++) {
      try {
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

        return _createNewSession(
          uid: uid,
          username: username,
          categoryId: categoryId,
          maxPlayers: maxPlayers,
        );
      } on StateError catch (e) {
        lastError = e;
        if (attempt == _maxMatchmakingAttempts - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }

    throw StateError('Matchmaking failed: $lastError');
  }

  Future<String> _createNewSession({
    required String uid,
    required String username,
    required String categoryId,
    required int maxPlayers,
  }) async {
    final questions = await _questionRepository.getQuestions(
      limit: _questionsPerGame,
      category: categoryId,
      questionTypes: QuestionType.values,
    );

    if (questions.isEmpty) {
      throw StateError('No questions available for category "$categoryId"');
    }

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
