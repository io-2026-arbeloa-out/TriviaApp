import 'package:flutter/foundation.dart';
import 'package:triviaapp/models/session_status.dart';

@immutable
class LiveGameState {
  final String _sessionId;
  final String _myUid;
  final SessionStatus _status;
  final int _currentQuestionIndex;
  final List<String> _questionIds;
  final List<PlayerLiveState> _players;
  final RoundResult? _lastRoundResult;

  const LiveGameState({
    required String sessionId,
    required String myUid,
    required SessionStatus status,
    required int currentQuestionIndex,
    required List<String> questionIds,
    required List<PlayerLiveState> players,
    RoundResult? lastRoundResult,
  })  : _sessionId = sessionId,
        _myUid = myUid,
        _status = status,
        _currentQuestionIndex = currentQuestionIndex,
        _questionIds = questionIds,
        _players = players,
        _lastRoundResult = lastRoundResult;

  String get sessionId => _sessionId;
  String get myUid => _myUid;
  SessionStatus get status => _status;
  int get currentQuestionIndex => _currentQuestionIndex;
  List<String> get questionIds => _questionIds;
  List<PlayerLiveState> get players => _players;
  RoundResult? get lastRoundResult => _lastRoundResult;

  List<PlayerLiveState> get activePlayers =>
      _players.where((p) => !p.isEliminated).toList();

  PlayerLiveState? get myState =>
      _players.where((p) => p.uid == _myUid).firstOrNull;

  bool get amIEliminated => myState?.isEliminated ?? false;
  int get activeCount => activePlayers.length;
}

@immutable
class PlayerLiveState {
  final String _uid;
  final String _username;
  final bool _isEliminated;
  final int _lotteryTickets;

  const PlayerLiveState({
    required String uid,
    required String username,
    required bool isEliminated,
    required int lotteryTickets,
  })  : _uid = uid,
        _username = username,
        _isEliminated = isEliminated,
        _lotteryTickets = lotteryTickets;

  String get uid => _uid;
  String get username => _username;
  bool get isEliminated => _isEliminated;
  int get lotteryTickets => _lotteryTickets;
}

@immutable
class RoundResult {
  /// null means nobody was eliminated this round (all answered correctly).
  final String? _eliminatedUid;
  final String? _eliminatedUsername;
  final bool _lotteryOccurred;

  /// uid → number of tickets
  final Map<String, int> _lotteryPool;

  const RoundResult({
    required String? eliminatedUid,
    required String? eliminatedUsername,
    required bool lotteryOccurred,
    required  Map<String, int> lotteryPool,
  })  : _eliminatedUid = eliminatedUid,
        _eliminatedUsername = eliminatedUsername,
        _lotteryOccurred = lotteryOccurred,
        _lotteryPool = lotteryPool;

  String? get eliminatedUid => _eliminatedUid;
  String? get eliminatedUsername => _eliminatedUsername;
  bool get lotteryOccurred => _lotteryOccurred;
  Map<String, int> get lotteryPool => _lotteryPool;
}