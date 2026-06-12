import 'package:triviaapp/interfaces/i_multiplayer_connection_service.dart';
import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

class MultiplayerConnectionService implements IMultiplayerConnectionService {
  final FirebaseSessionRepository _sessionRepository;
  final FirebaseQuestionRepository _questionRepository;

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
    required OnlineGameOptions settings,
  }) async {
    if (settings.isPrivate) {
      return _connectPrivate(uid: uid, username: username, settings: settings);
    }
    return _connectPublic(uid: uid, username: username, settings: settings);
  }

  // ── Public matchmaking ─────────────────────────────────────────────────────

  Future<String> _connectPublic({
    required String uid,
    required String username,
    required OnlineGameOptions settings,
  }) async {
    Object? lastError;

    for (var attempt = 0; attempt < _maxMatchmakingAttempts; attempt++) {
      try {
        final existingId = await _sessionRepository.findWaitingSession(
          categoryId: settings.categoryId,
          maxPlayers: settings.maxPlayers,
        );

        if (existingId != null) {
          return _sessionRepository.joinSession(
            sessionId: existingId,
            uid: uid,
            username: username,
          );
        }

        return _createNewSession(uid: uid, username: username, settings: settings);
      } on StateError catch (e) {
        lastError = e;
        if (attempt == _maxMatchmakingAttempts - 1) rethrow;
        await Future.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }

    throw StateError('Matchmaking failed: $lastError');
  }

  // ── Private game ───────────────────────────────────────────────────────────

  Future<String> _connectPrivate({
    required String uid,
    required String username,
    required OnlineGameOptions settings,
  }) async {
    final existingId = await _sessionRepository.findPrivateSession(
      entryCode: settings.entryCode!,
    );

    if (existingId != null) {
      return _sessionRepository.joinSession(
        sessionId: existingId,
        uid: uid,
        username: username,
      );
    }

    return _createNewSession(uid: uid, username: username, settings: settings);
  }

  // ── Shared ─────────────────────────────────────────────────────────────────

  Future<String> _createNewSession({
    required String uid,
    required String username,
    required OnlineGameOptions settings,
  }) async {
    final questions = await _questionRepository.getQuestions(
      limit: (settings.maxPlayers - 1) * 3,
      category: settings.categoryId,
      questionTypes: QuestionType.values,
      difficulty: settings.difficulty,
    );

    if (questions.isEmpty) {
      throw StateError(
        'No questions available for category "${settings.categoryId}" '
            'and difficulty "${settings.difficulty.name}"',
      );
    }

    return _sessionRepository.createSession(
      settings: settings,
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