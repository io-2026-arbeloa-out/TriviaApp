import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/live_game_state.dart';
import 'package:triviaapp/models/session_status.dart';

PlayerLiveState _player({
  String uid = 'uid1',
  String? username,
  String profilePicture = 'avatar.png',
  bool isEliminated = false,
  int lotteryTickets = 0,
}) =>
    PlayerLiveState(
      uid: uid,
      username: username ?? 'User-$uid',
      profilePicture: profilePicture,
      isEliminated: isEliminated,
      lotteryTickets: lotteryTickets,
    );

LiveGameState _state({
  String sessionId = 'sess1',
  String myUid = 'uid1',
  SessionStatus status = SessionStatus.answering,
  int currentQuestionIndex = 0,
  List<String>? questionIds,
  List<PlayerLiveState>? players,
  RoundResult? lastRoundResult,
}) =>
    LiveGameState(
      sessionId: sessionId,
      myUid: myUid,
      status: status,
      currentQuestionIndex: currentQuestionIndex,
      questionIds: questionIds ?? const ['q0', 'q1', 'q2'],
      players: players ?? [],
      lastRoundResult: lastRoundResult,
    );

RoundResult _roundResult({
  String? eliminatedUid = 'uid2',
  String? eliminatedUsername = 'Player2',
  bool lotteryOccurred = false,
  Map<String, int>? lotteryPool,
  bool opponentLeft = false,
}) =>
    RoundResult(
      eliminatedUid: eliminatedUid,
      eliminatedUsername: eliminatedUsername,
      lotteryOccurred: lotteryOccurred,
      lotteryPool: lotteryPool ?? {},
      opponentLeft: opponentLeft,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // ── PlayerLiveState ────────────────────────────────────────────────────────
  group('PlayerLiveState', () {
    test('getters return constructor values', () {
      final p = PlayerLiveState(
        uid: 'uid42',
        username: 'Alice',
        profilePicture: 'alice.png',
        isEliminated: true,
        lotteryTickets: 5,
      );

      expect(p.uid, 'uid42');
      expect(p.username, 'Alice');
      expect(p.profilePicture, 'alice.png');
      expect(p.isEliminated, isTrue);
      expect(p.lotteryTickets, 5);
    });

    test('lotteryTickets can be zero', () {
      expect(_player(lotteryTickets: 0).lotteryTickets, 0);
    });

    test('isEliminated defaults to false', () {
      expect(_player(isEliminated: false).isEliminated, isFalse);
    });
  });

  // ── RoundResult ────────────────────────────────────────────────────────────
  group('RoundResult', () {
    test('getters return constructor values', () {
      final r = RoundResult(
        eliminatedUid: 'uid2',
        eliminatedUsername: 'Bob',
        lotteryOccurred: true,
        lotteryPool: {'uid1': 3, 'uid2': 1},
        opponentLeft: false,
      );

      expect(r.eliminatedUid, 'uid2');
      expect(r.eliminatedUsername, 'Bob');
      expect(r.lotteryOccurred, isTrue);
      expect(r.lotteryPool, {'uid1': 3, 'uid2': 1});
      expect(r.opponentLeft, isFalse);
    });

    test('opponentLeft defaults to false', () {
      final r = RoundResult(
        eliminatedUid: null,
        eliminatedUsername: null,
        lotteryOccurred: false,
        lotteryPool: {},
      );
      expect(r.opponentLeft, isFalse);
    });

    test('opponentLeft can be set to true', () {
      expect(_roundResult(opponentLeft: true).opponentLeft, isTrue);
    });

    test('eliminatedUid can be null (all correct round)', () {
      final r = _roundResult(eliminatedUid: null, eliminatedUsername: null);
      expect(r.eliminatedUid, isNull);
      expect(r.eliminatedUsername, isNull);
    });

    test('lotteryPool can be empty', () {
      expect(_roundResult(lotteryPool: {}).lotteryPool, isEmpty);
    });

    test('lotteryPool preserves ticket counts', () {
      final pool = {'uid1': 2, 'uid2': 5, 'uid3': 0};
      expect(_roundResult(lotteryPool: pool).lotteryPool, pool);
    });
  });

  // ── LiveGameState.activePlayers ────────────────────────────────────────────
  group('LiveGameState.activePlayers', () {
    test('returns all players when none are eliminated', () {
      final state = _state(players: [
        _player(uid: 'a'),
        _player(uid: 'b'),
        _player(uid: 'c'),
      ]);
      expect(state.activePlayers.length, 3);
      expect(state.activePlayers.map((p) => p.uid), containsAll(['a', 'b', 'c']));
    });

    test('excludes eliminated players', () {
      final state = _state(players: [
        _player(uid: 'a', isEliminated: false),
        _player(uid: 'b', isEliminated: true),
        _player(uid: 'c', isEliminated: false),
      ]);
      final uids = state.activePlayers.map((p) => p.uid);
      expect(uids, unorderedEquals(['a', 'c']));
      expect(uids, isNot(contains('b')));
    });

    test('returns empty list when all players are eliminated', () {
      final state = _state(players: [
        _player(uid: 'a', isEliminated: true),
        _player(uid: 'b', isEliminated: true),
      ]);
      expect(state.activePlayers, isEmpty);
    });

    test('returns empty list when player list is empty', () {
      expect(_state(players: []).activePlayers, isEmpty);
    });

    test('does not mutate internal player list', () {
      final state = _state(players: [
        _player(uid: 'a', isEliminated: false),
        _player(uid: 'b', isEliminated: true),
      ]);
      expect(state.activePlayers.length, 1);
      // Calling again should return same count (no side effects).
      expect(state.activePlayers.length, 1);
    });
  });

  // ── LiveGameState.activeCount ──────────────────────────────────────────────
  group('LiveGameState.activeCount', () {
    test('counts only non-eliminated players', () {
      final state = _state(players: [
        _player(uid: 'a', isEliminated: false),
        _player(uid: 'b', isEliminated: true),
        _player(uid: 'c', isEliminated: false),
        _player(uid: 'd', isEliminated: false),
      ]);
      expect(state.activeCount, 3);
    });

    test('returns 0 when all are eliminated', () {
      final state = _state(players: [
        _player(uid: 'a', isEliminated: true),
        _player(uid: 'b', isEliminated: true),
      ]);
      expect(state.activeCount, 0);
    });

    test('returns 0 for empty player list', () {
      expect(_state(players: []).activeCount, 0);
    });

    test('consistent with activePlayers.length', () {
      final state = _state(players: [
        _player(uid: 'a', isEliminated: false),
        _player(uid: 'b', isEliminated: true),
        _player(uid: 'c', isEliminated: false),
      ]);
      expect(state.activeCount, state.activePlayers.length);
    });
  });

  // ── LiveGameState.myState ──────────────────────────────────────────────────
  group('LiveGameState.myState', () {
    test('returns player whose uid matches myUid', () {
      final state = _state(
        myUid: 'uid2',
        players: [
          _player(uid: 'uid1', username: 'Other'),
          _player(uid: 'uid2', username: 'Me'),
        ],
      );
      expect(state.myState?.uid, 'uid2');
      expect(state.myState?.username, 'Me');
    });

    test('exposes lotteryTickets of the matched player', () {
      final state = _state(
        myUid: 'uid2',
        players: [
          _player(uid: 'uid1'),
          _player(uid: 'uid2', lotteryTickets: 5),
        ],
      );
      expect(state.myState?.lotteryTickets, 5);
    });

    test('returns null when myUid is not in the player list', () {
      final state = _state(myUid: 'uid99', players: [_player(uid: 'uid1')]);
      expect(state.myState, isNull);
    });

    test('returns null when player list is empty', () {
      expect(_state(myUid: 'uid1', players: []).myState, isNull);
    });

    test('returns the correct player when there are many players', () {
      final players = List.generate(
        10,
            (i) => _player(uid: 'uid$i', username: 'User$i'),
      );
      final state = _state(myUid: 'uid7', players: players);
      expect(state.myState?.username, 'User7');
    });
  });

  // ── LiveGameState.amIEliminated ────────────────────────────────────────────
  group('LiveGameState.amIEliminated', () {
    test('true when my player is eliminated', () {
      final state = _state(
        myUid: 'uid1',
        players: [_player(uid: 'uid1', isEliminated: true)],
      );
      expect(state.amIEliminated, isTrue);
    });

    test('false when my player is active', () {
      final state = _state(
        myUid: 'uid1',
        players: [_player(uid: 'uid1', isEliminated: false)],
      );
      expect(state.amIEliminated, isFalse);
    });

    test('false when myUid is not found in player list', () {
      final state = _state(
        myUid: 'uid99',
        players: [_player(uid: 'uid1', isEliminated: true)],
      );
      expect(state.amIEliminated, isFalse);
    });

    test('false when player list is empty', () {
      expect(_state(myUid: 'uid1', players: []).amIEliminated, isFalse);
    });
  });

  // ── LiveGameState.lastRoundResult ──────────────────────────────────────────
  group('LiveGameState.lastRoundResult', () {
    test('is null when not provided', () {
      expect(_state().lastRoundResult, isNull);
    });

    test('is returned when set', () {
      final r = _roundResult();
      expect(_state(lastRoundResult: r).lastRoundResult, same(r));
    });

    test('exposes eliminatedUid, lotteryOccurred and lotteryPool', () {
      final result = RoundResult(
        eliminatedUid: 'uid2',
        eliminatedUsername: 'User-uid2',
        lotteryOccurred: true,
        lotteryPool: {'uid2': 3, 'uid3': 1},
      );
      final state = _state(lastRoundResult: result);

      expect(state.lastRoundResult?.eliminatedUid, 'uid2');
      expect(state.lastRoundResult?.lotteryOccurred, isTrue);
      expect(state.lastRoundResult?.lotteryPool, {'uid2': 3, 'uid3': 1});
    });

    test('eliminatedUid is null when everyone answered correctly', () {
      final result = RoundResult(
        eliminatedUid: null,
        eliminatedUsername: null,
        lotteryOccurred: false,
        lotteryPool: {},
      );
      expect(result.eliminatedUid, isNull);
    });

    test('opponentLeft flag is preserved', () {
      final result = RoundResult(
        eliminatedUid: null,
        eliminatedUsername: null,
        lotteryOccurred: false,
        lotteryPool: {},
        opponentLeft: true,
      );
      expect(result.opponentLeft, isTrue);
    });
  });

  // ── LiveGameState scalar getters ───────────────────────────────────────────
  group('LiveGameState scalar getters', () {
    test('sessionId', () => expect(_state(sessionId: 'abc').sessionId, 'abc'));
    test('myUid',    () => expect(_state(myUid: 'u99').myUid, 'u99'));
    test('status',   () => expect(_state(status: SessionStatus.resolving).status, SessionStatus.resolving));
    test('currentQuestionIndex', () => expect(_state(currentQuestionIndex: 7).currentQuestionIndex, 7));
    test('questionIds', () {
      final ids = ['q10', 'q11', 'q12'];
      expect(_state(questionIds: ids).questionIds, ids);
    });
  });
}