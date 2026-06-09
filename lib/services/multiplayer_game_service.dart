import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triviaapp/interfaces/i_multiplayer_game_service.dart';
import 'package:triviaapp/models/live_game_state.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/session_status.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

class MultiplayerGameService implements IMultiplayerGameService {
  final FirebaseSessionRepository _sessionRepository;
  final FirebaseQuestionRepository _questionRepository;
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final String _sessionId;

  late String _myUid;
  late String _myUsername;
  late List<Question> _questions;

  late final Future<void> ready;

  MultiplayerGameService({
    required String sessionId,
    FirebaseSessionRepository? sessionRepository,
    FirebaseQuestionRepository? questionRepository,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _sessionId = sessionId,
        _sessionRepository = sessionRepository ?? FirebaseSessionRepository(),
        _questionRepository = questionRepository ?? FirebaseQuestionRepository(),
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

    _questions = await _questionRepository.getQuestionsByIds(
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
    yield* _sessionRepository.sessionDocStream(_sessionId).map(_parse);
  }

  LiveGameState _parse(Map<String, dynamic> data) {
    // FIX: CF używa dwóch pól: 'status' (waiting/inProgress/finished) oraz
    // 'phase' (answering/resolving/finished). SessionStatus odpowiada wartościom
    // z 'phase', więc gdy status == 'inProgress' czytamy 'phase'.
    final statusRaw = data['status'] as String? ?? '';
    final phaseRaw  = data['phase']  as String? ?? '';
    final status    = SessionStatus.fromJson(
      statusRaw == 'inProgress' ? phaseRaw : statusRaw,
    );

    final currentQuestionIndex = data['currentQuestionIndex'] as int;
    final questionIds = List<String>.from(data['questionIds'] as List);

    final playersRaw = data['players'] as Map<String, dynamic>;
    final players = playersRaw.entries.map((entry) {
      final p = entry.value as Map<String, dynamic>;
      return PlayerLiveState(
        uid: entry.key,
        username: p['username'] as String,
        isEliminated: p['isEliminated'] as bool,
        lotteryTickets: p['lotteryTickets'] as int,
      );
    }).toList();

    RoundResult? lastRoundResult;

    if (status == SessionStatus.resolving) {
      final r = data['lastRoundResult'] as Map<String, dynamic>?;
      if (r != null) {
        lastRoundResult = RoundResult(
          eliminatedUid: r['eliminatedUid'] as String?,
          eliminatedUsername: r['eliminatedUsername'] as String?,
          lotteryOccurred: r['lotteryOccurred'] as bool,
          lotteryPool: Map<String, int>.from(r['lotteryPool'] as Map? ?? {}),
        );
      } else {
        throw StateError('Last round result not found');
      }
    }

    return LiveGameState(
      sessionId: _sessionId,
      myUid: _myUid,
      status: status,
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
    return _sessionRepository.submitAnswer(
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
    return _sessionRepository.leaveGame(sessionId: _sessionId, uid: _myUid);
  }

  @override
  Future<MultiplayerSessionData> fetchFinalSessionData() {
    return _sessionRepository.fetchArchivedSession(_sessionId);
  }
}