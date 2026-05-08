import 'package:flutter/foundation.dart';
import 'package:triviaapp/models/session_phase.dart';

export 'package:triviaapp/models/session_phase.dart';

/// Real-time game state built from multiple Firestore streams.
/// Used exclusively during an active multiplayer session.
/// After the game ends, [MultiplayerSessionData] is fetched from the archive.
@immutable
class LiveGameState {
  final String _sessionId;
  final String _myUid;
  final SessionPhase _phase;
  final int _currentQuestionIndex;
  final List<String> _questionIds;
  final List<PlayerLiveState> _players;
  final int _answersSubmittedCount;
  final RoundResult? _lastRoundResult;

  const LiveGameState({
    required String sessionId,
    required String myUid,
    required SessionPhase phase,
    required int currentQuestionIndex,
    required List<String> questionIds,
    required List<PlayerLiveState> players,
    required int answersSubmittedCount,
    RoundResult? lastRoundResult,
  })  : _sessionId = sessionId,
        _myUid = myUid,
        _phase = phase,
        _currentQuestionIndex = currentQuestionIndex,
        _questionIds = questionIds,
        _players = players,
        _answersSubmittedCount = answersSubmittedCount,
        _lastRoundResult = lastRoundResult;

  String get sessionId => _sessionId;
  String get myUid => _myUid;
  SessionPhase get phase => _phase;
  int get currentQuestionIndex => _currentQuestionIndex;
  List<String> get questionIds => _questionIds;
  List<PlayerLiveState> get players => _players;
  int get answersSubmittedCount => _answersSubmittedCount;
  RoundResult? get lastRoundResult => _lastRoundResult;

  List<PlayerLiveState> get activePlayers =>
      _players.where((p) => !p.isEliminated).toList();

  PlayerLiveState? get myState =>
      _players.where((p) => p.uid == _myUid).firstOrNull;

  bool get hasAnswered => myState?.hasAnsweredCurrentRound ?? false;
  bool get amIEliminated => myState?.isEliminated ?? false;
  int get activeCount => activePlayers.length;
}

@immutable
class PlayerLiveState {
  final String _uid;
  final String _username;
  final bool _isEliminated;
  final bool _hasAnsweredCurrentRound;

  /// Accumulated lottery tickets — increases by 1 each round
  /// the player is in the lottery but survives.
  final int _lotteryTickets;

  const PlayerLiveState({
    required String uid,
    required String username,
    required bool isEliminated,
    required bool hasAnsweredCurrentRound,
    required int lotteryTickets,
  })  : _uid = uid,
        _username = username,
        _isEliminated = isEliminated,
        _hasAnsweredCurrentRound = hasAnsweredCurrentRound,
        _lotteryTickets = lotteryTickets;

  String get uid => _uid;
  String get username => _username;
  bool get isEliminated => _isEliminated;
  bool get hasAnsweredCurrentRound => _hasAnsweredCurrentRound;
  int get lotteryTickets => _lotteryTickets;
}

@immutable
class RoundResult {
  /// null means nobody was eliminated this round (all answered correctly).
  final String? _eliminatedUid;
  final String? _eliminatedUsername;
  final bool _lotteryOccurred;

  /// UIDs of players who were in the lottery pool.
  final List<String> _lotteryPool;

  const RoundResult({
    required String? eliminatedUid,
    required String? eliminatedUsername,
    required bool lotteryOccurred,
    required List<String> lotteryPool,
  })  : _eliminatedUid = eliminatedUid,
        _eliminatedUsername = eliminatedUsername,
        _lotteryOccurred = lotteryOccurred,
        _lotteryPool = lotteryPool;

  String? get eliminatedUid => _eliminatedUid;
  String? get eliminatedUsername => _eliminatedUsername;
  bool get lotteryOccurred => _lotteryOccurred;
  List<String> get lotteryPool => _lotteryPool;
}