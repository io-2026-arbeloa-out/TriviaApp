import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/live_game_state.dart';
import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/models/session_status.dart';

class SessionSnapshot {
  final String sessionId;
  final SessionStatus status;
  final RoundPhase phase;
  final String categoryId;
  final List<String> questionIds;
  final int currentQuestionIndex;
  final List<PlayerLiveState> players;
  final List<String> playerUids;
  final OnlineGameOptions? options;
  final RoundResult? lastRoundResult;
  final bool resultsReady;

  SessionSnapshot({
    required this.sessionId,
    required this.status,
    required this.phase,
    required this.categoryId,
    required List<String> questionIds,
    required this.currentQuestionIndex,
    required List<PlayerLiveState> players,
    required List<String> playerUids,
    this.options,
    this.lastRoundResult,
    this.resultsReady = false,
  }) : questionIds = List.unmodifiable(questionIds),
       players = List.unmodifiable(players),
       playerUids = List.unmodifiable(playerUids);

  List<String> get playerNames => playerUids
      .map((uid) => players.firstWhere((p) => p.uid == uid).username)
      .toList();

  static T _field<T>(Map data, String key) {
    final value = data[key];
    if (value is! T) {
      throw FormatException('Missing or invalid session field: $key');
    }
    return value;
  }

  static List<String> _strings(Map data, String key) {
    final values = _field<List>(data, key);
    if (values.any((v) => v is! String || v.isEmpty)) {
      throw FormatException('Invalid session field: $key');
    }
    return values.cast<String>();
  }

  static T? _optional<T>(Map data, String key) {
    final value = data[key];
    if (value == null) return null;
    if (value is! T) throw FormatException('Invalid session field: $key');
    return value;
  }

  factory SessionSnapshot.fromJson(String id, Map<String, dynamic> data) {
    final status = SessionStatus.fromJson(data['status']);
    final phase = RoundPhase.fromJson(data['phase']);
    final category = _field<String>(data, 'categoryId');
    final questions = _strings(data, 'questionIds');
    final index = _field<int>(data, 'currentQuestionIndex');
    if (category.isEmpty ||
        questions.toSet().length != questions.length ||
        index < 0 ||
        (status == SessionStatus.inProgress && index >= questions.length)) {
      throw const FormatException('Invalid question position or category');
    }
    if ((status == SessionStatus.inProgress && phase == RoundPhase.finished) ||
        (status == SessionStatus.finished && phase != RoundPhase.finished)) {
      throw const FormatException(
        'Inconsistent session status and round phase',
      );
    }
    final difficulty = Difficulty.values
        .where((d) => d.name == data['difficulty'])
        .firstOrNull;
    if (difficulty == null) {
      throw const FormatException('Invalid session difficulty');
    }
    final options = OnlineGameOptions(
      categoryId: category,
      maxPlayers: _field<int>(data, 'maxPlayers'),
      questionTimeLimit: _field<int>(data, 'questionTimeLimit'),
      difficulty: difficulty,
      entryCode: _optional<int>(data, 'entryCode'),
    );
    try {
      options.validate();
    } on ArgumentError {
      throw const FormatException('Invalid lobby settings');
    }
    final rawPlayers = _field<Map>(data, 'players');
    final players = rawPlayers.entries.map((entry) {
      if (entry.key is! String || entry.value is! Map) {
        throw const FormatException('Invalid player');
      }
      final p = entry.value as Map;
      final tickets = _field<int>(p, 'lotteryTickets');
      if (tickets < 0) throw const FormatException('Invalid lottery tickets');
      return PlayerLiveState(
        uid: entry.key,
        username: _field<String>(p, 'username'),
        profilePicture:
            _optional<String>(p, 'profilePicture') ?? 'defaultAvatar.png',
        isEliminated: _field<bool>(p, 'isEliminated'),
        lotteryTickets: tickets,
      );
    }).toList();
    final uids = _strings(data, 'playerUids');
    if (uids.toSet().length != uids.length ||
        uids.any((uid) => !rawPlayers.containsKey(uid))) {
      throw const FormatException('Invalid player membership');
    }
    RoundResult? result;
    if (data['lastRoundResult'] != null) {
      final r = _field<Map>(data, 'lastRoundResult');
      final pool = _field<Map>(r, 'lotteryPool');
      if (pool.entries.any(
        (e) => e.key is! String || e.value is! int || e.value < 0,
      )) {
        throw const FormatException('Invalid lottery pool');
      }
      result = RoundResult(
        eliminatedUid: _optional<String>(r, 'eliminatedUid'),
        eliminatedUsername: _optional<String>(r, 'eliminatedUsername'),
        lotteryOccurred: _field<bool>(r, 'lotteryOccurred'),
        lotteryPool: Map<String, int>.unmodifiable(pool),
        opponentLeft: _optional<bool>(r, 'opponentLeft') ?? false,
      );
    }
    if (status == SessionStatus.inProgress &&
        phase == RoundPhase.resolving &&
        result == null) {
      throw const FormatException('Missing round result');
    }
    return SessionSnapshot(
      sessionId: id,
      status: status,
      phase: phase,
      categoryId: category,
      questionIds: questions,
      currentQuestionIndex: index,
      players: players,
      playerUids: uids,
      options: options,
      lastRoundResult: result,
      resultsReady: _optional<bool>(data, 'resultsReady') ?? false,
    );
  }

  factory SessionSnapshot.fromArchive(String id, Map<String, dynamic> data) {
    if (data['statsApplied'] != true) {
      throw StateError('Session results are not ready');
    }
    final players = _field<List>(data, 'playerResults').map((row) {
      if (row is! Map) throw const FormatException('Invalid archived player');
      return PlayerLiveState(
        uid: _field<String>(row, 'uid'),
        username: _field<String>(row, 'username'),
        profilePicture:
            _optional<String>(row, 'profilePicture') ?? 'defaultAvatar.png',
        isEliminated: _field<int>(row, 'placement') != 1,
        lotteryTickets: _field<int>(row, 'lotteryTimesIn'),
      );
    }).toList();
    final questions = _strings(data, 'questionIds');
    final rounds = _field<List>(data, 'rounds');
    final index = rounds.isEmpty
        ? 0
        : _field<int>(rounds.last as Map, 'roundIndex');
    if (questions.isEmpty || index < 0 || index >= questions.length) {
      throw const FormatException('Invalid archived question position');
    }
    return SessionSnapshot(
      sessionId: id,
      status: SessionStatus.finished,
      phase: RoundPhase.finished,
      categoryId: _field<String>(data, 'categoryId'),
      questionIds: questions,
      currentQuestionIndex: index,
      players: players,
      playerUids: players.map((p) => p.uid).toList(),
      resultsReady: true,
    );
  }

  LiveGameState forPlayer(String uid) => LiveGameState(
    sessionId: sessionId,
    myUid: uid,
    status: status,
    phase: phase,
    resultsReady: resultsReady,
    currentQuestionIndex: currentQuestionIndex,
    questionIds: questionIds,
    players: players,
    lastRoundResult: lastRoundResult,
  );
}
