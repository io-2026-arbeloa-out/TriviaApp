import 'package:flutter/foundation.dart';
import 'package:triviaapp/models/game_mode.dart';

export 'package:triviaapp/models/game_mode.dart';

@immutable
class MultiplayerSessionData {
  final String _sessionId;
  final String _categoryId;
  final GameMode _gameMode;
  final DateTime _sessionStartTime;
  final DateTime _gameStartTime;
  final DateTime _endTime;

  /// Sorted by placement ascending (index 0 = winner).
  final List<PlayerResult> _playerResults;

  final List<RoundRecord> _rounds;

  const MultiplayerSessionData({
    required String sessionId,
    required String categoryId,
    required GameMode gameMode,
    required DateTime sessionStartTime,
    required DateTime gameStartTime,
    required DateTime endTime,
    required List<PlayerResult> playerResults,
    required List<RoundRecord> rounds,
  })  : _sessionId = sessionId,
        _categoryId = categoryId,
        _gameMode = gameMode,
        _sessionStartTime = sessionStartTime,
        _gameStartTime = gameStartTime,
        _endTime = endTime,
        _playerResults = playerResults,
        _rounds = rounds;

  String get sessionId => _sessionId;
  String get categoryId => _categoryId;
  GameMode get gameMode => _gameMode;
  DateTime get sessionStartTime => _sessionStartTime;
  DateTime get gameStartTime => _gameStartTime;
  DateTime get endTime => _endTime;
  List<PlayerResult> get playerResults => _playerResults;
  List<RoundRecord> get rounds => _rounds;

  PlayerResult? get winner =>
      _playerResults.where((r) => r.placement == 1).firstOrNull;

  PlayerResult? playerByUid(String uid) =>
      _playerResults.where((r) => r.uid == uid).firstOrNull;

  factory MultiplayerSessionData.fromJson(Map<String, dynamic> json) {
    return MultiplayerSessionData(
      sessionId: json['sessionId'] as String,
      categoryId: json['categoryId'] as String,
      gameMode: GameMode.fromJson(json['gameMode'] as String?),
      sessionStartTime: DateTime.parse(json['sessionStartTime'] as String),
      gameStartTime: DateTime.parse(json['gameStartTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      playerResults: (json['playerResults'] as List<dynamic>)
          .map((e) => PlayerResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      rounds: (json['rounds'] as List<dynamic>)
          .map((e) => RoundRecord.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'sessionId': _sessionId,
    'categoryId': _categoryId,
    'gameMode': _gameMode.name,
    'sessionStartTime': _sessionStartTime.toIso8601String(),
    'gameStartTime': _gameStartTime.toIso8601String(),
    'endTime': _endTime.toIso8601String(),
    'playerResults': _playerResults.map((r) => r.toJson()).toList(),
    'rounds': _rounds.map((r) => r.toJson()).toList(),
  };
}

@immutable
class PlayerResult {
  final String _uid;
  final String _username;
  final int _placement;
  final int _correctAnswers;
  final int _totalAnswers;

  /// 0 for the winner.
  final int _eliminationRound;
  final int _lotteryTimesIn;

  const PlayerResult({
    required String uid,
    required String username,
    required int placement,
    required int correctAnswers,
    required int totalAnswers,
    int eliminationRound = 0,
    required int lotteryTimesIn,
  })  : _uid = uid,
        _username = username,
        _placement = placement,
        _correctAnswers = correctAnswers,
        _totalAnswers = totalAnswers,
        _eliminationRound = eliminationRound,
        _lotteryTimesIn = lotteryTimesIn;

  String get uid => _uid;
  String get username => _username;
  int get placement => _placement;
  int get correctAnswers => _correctAnswers;
  int get totalAnswers => _totalAnswers;
  int? get eliminationRound => _eliminationRound;
  int get lotteryTimesIn => _lotteryTimesIn;

  factory PlayerResult.fromJson(Map<String, dynamic> json) => PlayerResult(
    uid: json['uid'] as String,
    username: json['username'] as String,
    placement: json['placement'] as int,
    correctAnswers: json['correctAnswers'] as int,
    totalAnswers: json['totalAnswers'] as int,
    eliminationRound: (json['eliminationRound'] as int?) ?? 0,
    lotteryTimesIn: json['lotteryTimesIn'] as int,
  );

  Map<String, dynamic> toJson() => {
    'uid': _uid,
    'username': _username,
    'placement': _placement,
    'correctAnswers': _correctAnswers,
    'totalAnswers': _totalAnswers,
    'eliminationRound': _eliminationRound,
    'lotteryTimesIn': _lotteryTimesIn,
  };
}

@immutable
class RoundRecord {
  final int _roundIndex;
  final String _questionId;

  /// uid → answer text submitted by that player.
  final Map<String, String> _playerAnswers;

  /// uid → whether the answer was correct
  final Map<String, bool> _isCorrect;

  final bool _lotteryOccurred;

  /// uid → number of tickets
  final Map<String, int> _lotteryPool;

  /// null when nobody was eliminated (all answered correctly).
  final String? _eliminatedUid;

  const RoundRecord({
    required int roundIndex,
    required String questionId,
    required Map<String, String> playerAnswers,
    required Map<String, bool> isCorrect,
    required bool lotteryOccurred,
    required Map<String, int> lotteryPool,
    String? eliminatedUid,
  })  : _roundIndex = roundIndex,
        _questionId = questionId,
        _playerAnswers = playerAnswers,
        _isCorrect = isCorrect,
        _lotteryOccurred = lotteryOccurred,
        _lotteryPool = lotteryPool,
        _eliminatedUid = eliminatedUid;

  int get roundIndex => _roundIndex;
  String get questionId => _questionId;
  Map<String, String> get playerAnswers => _playerAnswers;
  Map<String, bool> get isCorrect => _isCorrect;
  bool get lotteryOccurred => _lotteryOccurred;
  Map<String, int> get lotteryPool => _lotteryPool;
  String? get eliminatedUid => _eliminatedUid;

  factory RoundRecord.fromJson(Map<String, dynamic> json) => RoundRecord(
    roundIndex: json['roundIndex'] as int,
    questionId: json['questionId'] as String,
    playerAnswers: Map<String, String>.from(
        json['playerAnswers'] as Map<dynamic, dynamic>),
    isCorrect:
    Map<String, bool>.from(json['isCorrect'] as Map<dynamic, dynamic>),
    lotteryOccurred: json['lotteryOccurred'] as bool,
    lotteryPool: Map<String, int>.from(json['lotteryPool'] as Map<dynamic, dynamic>),
    eliminatedUid: json['eliminatedUid'] as String?,
  );

  Map<String, dynamic> toJson() => {
    'roundIndex': _roundIndex,
    'questionId': _questionId,
    'playerAnswers': _playerAnswers,
    'isCorrect': _isCorrect,
    'lotteryOccurred': _lotteryOccurred,
    'lotteryPool': _lotteryPool,
    'eliminatedUid': _eliminatedUid,
  };
}