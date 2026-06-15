import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';

Map<String, dynamic> _playerJson({
  String uid = 'uid1',
  String username = 'Player',
  int placement = 1,
  int correctAnswers = 5,
  int totalAnswers = 10,
  int? eliminationRound = 0,
  int lotteryTimesIn = 0,
}) =>
    {
      'uid': uid,
      'username': username,
      'placement': placement,
      'correctAnswers': correctAnswers,
      'totalAnswers': totalAnswers,
      'eliminationRound': eliminationRound,
      'lotteryTimesIn': lotteryTimesIn,
    };

Map<String, dynamic> _roundJson({
  int roundIndex = 0,
  String questionId = 'q0',
  Map<String, String>? playerAnswers,
  Map<String, bool>? isCorrect,
  bool lotteryOccurred = false,
  Map<String, int>? lotteryPool,
  String? eliminatedUid,
}) =>
    {
      'roundIndex': roundIndex,
      'questionId': questionId,
      'playerAnswers': playerAnswers ?? {'uid1': 'A'},
      'isCorrect': isCorrect ?? {'uid1': true},
      'lotteryOccurred': lotteryOccurred,
      'lotteryPool': lotteryPool ?? {},
      'eliminatedUid': eliminatedUid,
    };

const _ts = '2024-06-01T12:00:00.000Z';

Map<String, dynamic> _sessionJson({
  String sessionId = 'sess1',
  String categoryId = 'general',
  String gameMode = 'casual',
  String sessionStartTime = _ts,
  String gameStartTime = _ts,
  String endTime = _ts,
  List<Map<String, dynamic>>? playerResults,
  List<Map<String, dynamic>>? rounds,
}) =>
    {
      'sessionId': sessionId,
      'categoryId': categoryId,
      'gameMode': gameMode,
      'sessionStartTime': sessionStartTime,
      'gameStartTime': gameStartTime,
      'endTime': endTime,
      'playerResults': playerResults ?? [_playerJson()],
      'rounds': rounds ?? [],
    };

// ---------------------------------------------------------------------------
// Object builders (used for constructor-based and round-trip tests)
// ---------------------------------------------------------------------------

PlayerResult _result({
  required String uid,
  required int placement,
  int correctAnswers = 0,
  int totalAnswers = 0,
  int lotteryTimesIn = 0,
  int eliminationRound = 0,
}) =>
    PlayerResult(
      uid: uid,
      username: 'User-$uid',
      placement: placement,
      correctAnswers: correctAnswers,
      totalAnswers: totalAnswers,
      eliminationRound: eliminationRound,
      lotteryTimesIn: lotteryTimesIn,
    );

MultiplayerSessionData _session({
  List<PlayerResult>? playerResults,
  List<RoundRecord>? rounds,
}) =>
    MultiplayerSessionData(
      sessionId: 'sid1',
      categoryId: 'general',
      gameMode: GameMode.casual,
      sessionStartTime: DateTime(2024),
      gameStartTime: DateTime(2024),
      endTime: DateTime(2024, 1, 1, 0, 5),
      playerResults: playerResults ?? [],
      rounds: rounds ?? [],
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── PlayerResult ───────────────────────────────────────────────────────────
  group('PlayerResult.fromJson', () {
    test('parses all fields', () {
      final r = PlayerResult.fromJson(_playerJson(
        uid: 'uid42',
        username: 'Bob',
        placement: 3,
        correctAnswers: 7,
        totalAnswers: 9,
        eliminationRound: 4,
        lotteryTimesIn: 2,
      ));

      expect(r.uid, 'uid42');
      expect(r.username, 'Bob');
      expect(r.placement, 3);
      expect(r.correctAnswers, 7);
      expect(r.totalAnswers, 9);
      expect(r.eliminationRound, 4);
      expect(r.lotteryTimesIn, 2);
    });

    test('eliminationRound defaults to 0 when null in JSON', () {
      final json = _playerJson()..['eliminationRound'] = null;
      expect(PlayerResult.fromJson(json).eliminationRound, 0);
    });

    test('eliminationRound defaults to 0 when absent from JSON', () {
      final json = {
        'uid': 'u1',
        'username': 'Bob',
        'placement': 2,
        'correctAnswers': 3,
        'totalAnswers': 5,
        'lotteryTimesIn': 0,
        // eliminationRound intentionally absent
      };
      expect(PlayerResult.fromJson(json).eliminationRound, 0);
    });

    test('eliminationRound of 0 is preserved', () {
      expect(
        PlayerResult.fromJson(_playerJson(eliminationRound: 0)).eliminationRound,
        0,
      );
    });
  });

  group('PlayerResult.toJson', () {
    test('serializes all fields', () {
      const r = PlayerResult(
        uid: 'uid5',
        username: 'Charlie',
        placement: 2,
        correctAnswers: 8,
        totalAnswers: 10,
        eliminationRound: 3,
        lotteryTimesIn: 1,
      );
      final json = r.toJson();

      expect(json['uid'], 'uid5');
      expect(json['username'], 'Charlie');
      expect(json['placement'], 2);
      expect(json['correctAnswers'], 8);
      expect(json['totalAnswers'], 10);
      expect(json['eliminationRound'], 3);
      expect(json['lotteryTimesIn'], 1);
    });
  });

  group('PlayerResult round-trip', () {
    test('fromJson(toJson(x)) preserves all fields', () {
      const original = PlayerResult(
        uid: 'uid9',
        username: 'Dave',
        placement: 4,
        correctAnswers: 3,
        totalAnswers: 10,
        eliminationRound: 2,
        lotteryTimesIn: 3,
      );
      final rt = PlayerResult.fromJson(original.toJson());

      expect(rt.uid, original.uid);
      expect(rt.username, original.username);
      expect(rt.placement, original.placement);
      expect(rt.correctAnswers, original.correctAnswers);
      expect(rt.totalAnswers, original.totalAnswers);
      expect(rt.eliminationRound, original.eliminationRound);
      expect(rt.lotteryTimesIn, original.lotteryTimesIn);
    });
  });

  // ── RoundRecord ────────────────────────────────────────────────────────────
  group('RoundRecord.fromJson', () {
    test('parses all fields', () {
      final r = RoundRecord.fromJson(_roundJson(
        roundIndex: 5,
        questionId: 'q99',
        playerAnswers: {'uid1': 'B', 'uid2': 'C'},
        isCorrect: {'uid1': false, 'uid2': true},
        lotteryOccurred: true,
        lotteryPool: {'uid1': 2, 'uid2': 0},
        eliminatedUid: 'uid1',
      ));

      expect(r.roundIndex, 5);
      expect(r.questionId, 'q99');
      expect(r.playerAnswers, {'uid1': 'B', 'uid2': 'C'});
      expect(r.isCorrect, {'uid1': false, 'uid2': true});
      expect(r.lotteryOccurred, isTrue);
      expect(r.lotteryPool, {'uid1': 2, 'uid2': 0});
      expect(r.eliminatedUid, 'uid1');
    });

    test('eliminatedUid can be null', () {
      expect(RoundRecord.fromJson(_roundJson(eliminatedUid: null)).eliminatedUid, isNull);
    });

    test('lotteryPool can be empty', () {
      expect(RoundRecord.fromJson(_roundJson(lotteryPool: {})).lotteryPool, isEmpty);
    });
  });

  group('RoundRecord.toJson', () {
    test('serializes all fields', () {
      const r = RoundRecord(
        roundIndex: 2,
        questionId: 'q3',
        playerAnswers: {'uid1': 'D'},
        isCorrect: {'uid1': false},
        lotteryOccurred: false,
        lotteryPool: {},
        eliminatedUid: null,
      );
      final json = r.toJson();

      expect(json['roundIndex'], 2);
      expect(json['questionId'], 'q3');
      expect(json['playerAnswers'], {'uid1': 'D'});
      expect(json['isCorrect'], {'uid1': false});
      expect(json['lotteryOccurred'], isFalse);
      expect(json['lotteryPool'], isEmpty);
      expect(json['eliminatedUid'], isNull);
    });
  });

  group('RoundRecord round-trip', () {
    test('fromJson(toJson(x)) preserves all fields', () {
      const original = RoundRecord(
        roundIndex: 3,
        questionId: 'q7',
        playerAnswers: {'uid1': 'A', 'uid2': 'B'},
        isCorrect: {'uid1': true, 'uid2': false},
        lotteryOccurred: true,
        lotteryPool: {'uid2': 1},
        eliminatedUid: 'uid2',
      );
      final rt = RoundRecord.fromJson(original.toJson());

      expect(rt.roundIndex, original.roundIndex);
      expect(rt.questionId, original.questionId);
      expect(rt.playerAnswers, original.playerAnswers);
      expect(rt.isCorrect, original.isCorrect);
      expect(rt.lotteryOccurred, original.lotteryOccurred);
      expect(rt.lotteryPool, original.lotteryPool);
      expect(rt.eliminatedUid, original.eliminatedUid);
    });

    test('preserves null eliminatedUid', () {
      const r = RoundRecord(
        roundIndex: 0,
        questionId: 'q1',
        playerAnswers: {},
        isCorrect: {},
        lotteryOccurred: false,
        lotteryPool: {},
        eliminatedUid: null,
      );
      expect(RoundRecord.fromJson(r.toJson()).eliminatedUid, isNull);
    });
  });

  // ── MultiplayerSessionData.fromJson ───────────────────────────────────────
  group('MultiplayerSessionData.fromJson', () {
    test('parses sessionId and categoryId', () {
      final s = MultiplayerSessionData.fromJson(
        _sessionJson(sessionId: 'sess42', categoryId: 'science'),
      );
      expect(s.sessionId, 'sess42');
      expect(s.categoryId, 'science');
    });

    test('parses timestamps as DateTime', () {
      final s = MultiplayerSessionData.fromJson(_sessionJson(
        sessionStartTime: '2024-01-01T10:00:00.000Z',
        gameStartTime: '2024-01-01T10:01:00.000Z',
        endTime: '2024-01-01T10:30:00.000Z',
      ));
      expect(s.sessionStartTime, DateTime.parse('2024-01-01T10:00:00.000Z'));
      expect(s.gameStartTime, DateTime.parse('2024-01-01T10:01:00.000Z'));
      expect(s.endTime, DateTime.parse('2024-01-01T10:30:00.000Z'));
    });

    test('parses playerResults list', () {
      final s = MultiplayerSessionData.fromJson(_sessionJson(
        playerResults: [
          _playerJson(uid: 'uid1', placement: 1),
          _playerJson(uid: 'uid2', placement: 2),
        ],
      ));
      expect(s.playerResults.length, 2);
    });

    test('parses rounds list', () {
      final s = MultiplayerSessionData.fromJson(_sessionJson(
        rounds: [_roundJson(roundIndex: 0), _roundJson(roundIndex: 1)],
      ));
      expect(s.rounds.length, 2);
    });

    test('empty playerResults and rounds are valid', () {
      final s = MultiplayerSessionData.fromJson(
        _sessionJson(playerResults: [], rounds: []),
      );
      expect(s.playerResults, isEmpty);
      expect(s.rounds, isEmpty);
    });
  });

  // ── MultiplayerSessionData.toJson ─────────────────────────────────────────
  group('MultiplayerSessionData.toJson', () {
    test('contains all required keys with correct types', () {
      final json = MultiplayerSessionData.fromJson(_sessionJson()).toJson();

      expect(json['sessionId'], isA<String>());
      expect(json['categoryId'], isA<String>());
      expect(json['gameMode'], isA<String>());
      expect(json['sessionStartTime'], isA<String>());
      expect(json['gameStartTime'], isA<String>());
      expect(json['endTime'], isA<String>());
      expect(json['playerResults'], isA<List>());
      expect(json['rounds'], isA<List>());
    });
  });

  // ── MultiplayerSessionData round-trip ─────────────────────────────────────
  group('MultiplayerSessionData round-trip', () {
    test('preserves sessionId, categoryId, gameMode and list sizes', () {
      final original = MultiplayerSessionData.fromJson(_sessionJson(
        sessionId: 'rt-sess',
        categoryId: 'history',
        playerResults: [
          _playerJson(uid: 'u1', placement: 1),
          _playerJson(uid: 'u2', placement: 2),
        ],
        rounds: [_roundJson(roundIndex: 0), _roundJson(roundIndex: 1)],
      ));
      final rt = MultiplayerSessionData.fromJson(original.toJson());

      expect(rt.sessionId, original.sessionId);
      expect(rt.categoryId, original.categoryId);
      expect(rt.gameMode, original.gameMode);
      expect(rt.playerResults.length, original.playerResults.length);
      expect(rt.rounds.length, original.rounds.length);
    });

    test('preserves all PlayerResult fields across multiple players', () {
      final original = _session(playerResults: [
        _result(
          uid: 'u1',
          placement: 1,
          correctAnswers: 7,
          totalAnswers: 10,
          lotteryTimesIn: 3,
          eliminationRound: 0,
        ),
        _result(uid: 'u2', placement: 2, correctAnswers: 3, totalAnswers: 10),
      ]);
      final restored = MultiplayerSessionData.fromJson(original.toJson());

      final r = restored.playerResults.firstWhere((p) => p.uid == 'u1');
      expect(r.correctAnswers, 7);
      expect(r.totalAnswers, 10);
      expect(r.lotteryTimesIn, 3);
    });

    test('preserves all RoundRecord fields', () {
      const round = RoundRecord(
        roundIndex: 1,
        questionId: 'q2',
        playerAnswers: {'u1': '1863', 'u2': '1830'},
        isCorrect: {'u1': true, 'u2': false},
        lotteryOccurred: true,
        lotteryPool: {'u2': 2},
        eliminatedUid: 'u2',
      );
      final original = _session(rounds: [round]);
      final restored = MultiplayerSessionData.fromJson(original.toJson());

      expect(restored.rounds.length, 1);
      final r = restored.rounds.first;
      expect(r.roundIndex, 1);
      expect(r.questionId, 'q2');
      expect(r.playerAnswers, {'u1': '1863', 'u2': '1830'});
      expect(r.isCorrect, {'u1': true, 'u2': false});
      expect(r.lotteryOccurred, isTrue);
      expect(r.lotteryPool, {'u2': 2});
      expect(r.eliminatedUid, 'u2');
    });
  });

  // ── MultiplayerSessionData.winner ──────────────────────────────────────────
  group('MultiplayerSessionData.winner', () {
    test('returns player with placement == 1', () {
      final s = _session(playerResults: [
        _result(uid: 'u1', placement: 2),
        _result(uid: 'u2', placement: 1),
        _result(uid: 'u3', placement: 3),
      ]);
      expect(s.winner?.uid, 'u2');
    });

    test('returns null when no player has placement 1', () {
      final s = _session(playerResults: [
        _result(uid: 'u1', placement: 2),
        _result(uid: 'u2', placement: 3),
      ]);
      expect(s.winner, isNull);
    });

    test('returns null for empty player list', () {
      expect(_session().winner, isNull);
    });
  });

  // ── MultiplayerSessionData.playerByUid ────────────────────────────────────
  group('MultiplayerSessionData.playerByUid', () {
    test('returns correct player by username', () {
      final s = MultiplayerSessionData.fromJson(_sessionJson(playerResults: [
        _playerJson(uid: 'uid1', username: 'Alice'),
        _playerJson(uid: 'uid2', username: 'Bob'),
      ]));
      expect(s.playerByUid('uid2')?.username, 'Bob');
    });

    test('returns correct player by correctAnswers', () {
      final s = _session(playerResults: [
        _result(uid: 'u1', placement: 1, correctAnswers: 8),
        _result(uid: 'u2', placement: 2),
      ]);
      expect(s.playerByUid('u1')?.correctAnswers, 8);
    });

    test('returns null for unknown uid', () {
      final s = _session(playerResults: [_result(uid: 'u1', placement: 1)]);
      expect(s.playerByUid('u99'), isNull);
    });

    test('returns null for empty player list', () {
      expect(_session().playerByUid('uid1'), isNull);
    });
  });
}