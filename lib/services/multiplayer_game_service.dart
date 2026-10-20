import 'package:triviaapp/interfaces/i_multiplayer_game_service.dart';
import 'package:triviaapp/models/live_game_state.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/game_answer.dart';
import 'package:triviaapp/models/session_status.dart';
import 'package:triviaapp/repositories/auth_repository.dart';
import 'package:triviaapp/repositories/profile_repository.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/session_repository.dart';

class MultiplayerGameService implements IMultiplayerGameService {
  final SessionRepository _sessionRepository;
  final FirebaseQuestionRepository _questionRepository;
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  @override
  final String sessionId;
  @override
  late String myUid;
  @override
  late String myUsername;
  @override
  late List<Question> questions;
  late final Future<void> ready;

  MultiplayerGameService({
    required this.sessionId,
    required SessionRepository sessionRepository,
    required FirebaseQuestionRepository questionRepository,
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
  }) : _sessionRepository = sessionRepository,
       _questionRepository = questionRepository,
       _authRepository = authRepository,
       _profileRepository = profileRepository {
    ready = _initialize();
  }

  Future<void> _initialize() async {
    if (!_authRepository.isSignedIn) throw StateError('No authenticated user');
    final profile = await _profileRepository.getProfileData();
    myUid = profile.uid;
    myUsername = profile.username;
    final session = await _sessionRepository.sessionDocStream(sessionId).first;
    if (session.questionIds.isEmpty) {
      throw StateError('Session has no questions');
    }
    questions = List.unmodifiable(
      await _questionRepository.getQuestionsByIds(
        category: session.categoryId,
        ids: session.questionIds,
      ),
    );
  }

  @override
  Stream<LiveGameState> buildLiveGameStateStream() async* {
    await ready;
    yield* _sessionRepository
        .sessionDocStream(sessionId)
        .where(
          (session) =>
              session.status != SessionStatus.finished || session.resultsReady,
        )
        .map((session) => session.forPlayer(myUid));
  }

  @override
  Future<GameAnswer> submitAnswer({
    required int roundIndex,
    required String questionId,
    required String answer,
  }) => _sessionRepository.submitAnswer(
    sessionId: sessionId,
    uid: myUid,
    roundIndex: roundIndex,
    questionId: questionId,
    answer: answer,
  );

  @override
  Future<void> leaveGame() async {
    await ready;
    await _sessionRepository.leaveGame(sessionId: sessionId, uid: myUid);
  }

  @override
  Future<MultiplayerSessionData> fetchFinalSessionData() =>
      _sessionRepository.fetchArchivedSession(sessionId);
}
