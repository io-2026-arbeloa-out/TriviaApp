import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triviaapp/interfaces/i_multiplayer_game_service.dart';
import 'package:triviaapp/models/live_game_state.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/session_phase.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

class MultiplayerGameService implements IMultiplayerGameService {
  final FirebaseSessionRepository _repo;
  final FirebaseQuestionRepository _questionRepo;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final String _sessionId;

  late String _myUid;
  late String _myUsername;
  late List<Question> _questions;

  late final Future<void> ready;

  MultiplayerGameService({
    required String sessionId,
    FirebaseSessionRepository? repo,
    FirebaseQuestionRepository? questionRepo,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _sessionId = sessionId,
        _repo = repo ?? FirebaseSessionRepository(),
        _questionRepo = questionRepo ?? FirebaseQuestionRepository(),
        _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance {
    ready = _initialize();
  }

  Future<void> _initialize() async {
    final user = _auth.currentUser;
    if (user == null) throw StateError('No authenticated user');
    _myUid = user.uid;

    final userSnap = await _firestore.collection('users').doc(_myUid).get();
    _myUsername = userSnap.data()?['username'] as String? ?? '';

    final sessionSnap = await _firestore.collection('sessions').doc(_sessionId).get();
    if (!sessionSnap.exists) {
      throw StateError('Session $_sessionId not found');
    }

    final data = sessionSnap.data()!;
    final questionIds = List<String>.from(data['questionIds'] as List? ?? []);
    final categoryId = data['categoryId'] as String;

    _questions = await _questionRepo.getQuestionsByIds(
      category: categoryId,
      ids: questionIds,
    );
  }

  @override
  String get sessionId => _sessionId;

  @override
  String get myUid => _myUid;

  @override
  String get myUsername => _myUsername;

  @override
  List<Question> get questions => _questions;

  @override
  Stream<LiveGameState> buildLiveGameStateStream() async* {
    await ready;
    yield* _repo.sessionDocStream(_sessionId).map(_parse);
  }

  LiveGameState _parse(Map<String, dynamic> data) {
    final status = data['status'] as String? ?? 'waiting';
    final phaseStr = data['phase'] as String? ?? 'answering';
    final currentQuestionIndex = data['currentQuestionIndex'] as int? ?? 0;
    final questionIds = List<String>.from(data['questionIds'] as List? ?? []);

    final playersRaw = data['players'] as Map<String, dynamic>? ?? {};
    final players = playersRaw.entries.map((entry) {
      final p = entry.value as Map<String, dynamic>;
      return PlayerLiveState(
        uid: entry.key,
        username: p['username'] as String? ?? '',
        isEliminated: p['isEliminated'] as bool? ?? false,
        lotteryTickets: p['lotteryTickets'] as int? ?? 0,
      );
    }).toList();

    SessionPhase phase;
    RoundResult? lastRoundResult;

    switch (status) {
      case 'waiting':
        phase = SessionPhase.waiting;
      case 'finished':
        phase = SessionPhase.finished;
      default:
        if (phaseStr == 'resolving') {
          phase = SessionPhase.resolving;
          final r = data['lastRoundResult'] as Map<String, dynamic>?;
          if (r != null) {
            lastRoundResult = RoundResult(
              eliminatedUid: r['eliminatedUid'] as String?,
              eliminatedUsername: r['eliminatedUsername'] as String?,
              lotteryOccurred: r['lotteryOccurred'] as bool? ?? false,
              lotteryPool: List<String>.from(r['lotteryPool'] as List? ?? []),
            );
          }
        } else {
          phase = SessionPhase.answering;
        }
    }

    return LiveGameState(
      sessionId: _sessionId,
      myUid: _myUid,
      phase: phase,
      currentQuestionIndex: currentQuestionIndex,
      questionIds: questionIds,
      players: players,
      lastRoundResult: lastRoundResult,
    );
  }

  @override
  Future<void> submitAnswer({
    required int roundIndex,
    required String questionId,
    required String answer,
  }) {
    return _repo.submitAnswer(
      sessionId: _sessionId,
      uid: _myUid,
      roundIndex: roundIndex,
      questionId: questionId,
      answer: answer,
    );
  }

  @override
  Future<void> leaveGame() async {
    await ready;
    return _repo.leaveGame(sessionId: _sessionId, uid: _myUid);
  }

  @override
  Future<MultiplayerSessionData> fetchFinalSessionData() {
    return _repo.fetchArchivedSession(_sessionId);
  }
}
