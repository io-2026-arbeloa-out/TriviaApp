import 'dart:async';

import 'package:triviaapp/models/session_phase.dart';
import 'package:triviaapp/interfaces/i_multiplayer_game_service.dart';
import 'package:triviaapp/models/live_game_state.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

class MultiplayerGameService implements IMultiplayerGameService {
  final FirebaseSessionRepository _repo;

  MultiplayerGameService({
    FirebaseSessionRepository? repo,
  }) : _repo = repo ?? FirebaseSessionRepository();

  /// Combines four Firestore streams into one [LiveGameState] stream:
  ///
  ///   1. Session document  (status, currentQuestionIndex, questionIds)
  ///   2. Players subcollection  (isEliminated, lotteryTickets)
  ///   3. Current round document  (round status, eliminatedUid, lottery data)
  ///   4. Answers subcollection for current round  (who has answered)
  ///
  /// Subscriptions 3 & 4 are recreated whenever [currentQuestionIndex]
  /// changes so we always track the active round.
  @override
  Stream<LiveGameState> buildLiveGameStateStream({
    required String sessionId,
    required String myUid,
  }) {
    // broadcast so the widget tree can listen from multiple places if needed
    final controller = StreamController<LiveGameState>.broadcast();

    // Latest snapshots from each source
    Map<String, dynamic>? latestSession;
    List<Map<String, dynamic>> latestPlayers = [];
    Map<String, dynamic>? latestRound;
    int latestAnswersCount = 0;
    Set<String> latestAnsweredUids = {};

    int? subscribedRoundIndex;
    StreamSubscription<Map<String, dynamic>?>? roundSub;
    StreamSubscription<({int count, Set<String> answeredUids})>? answersSub;

    // ── Emit ──────────────────────────────────────────────────────────────

    void tryEmit() {
      final session = latestSession;
      if (session == null) return;

      final status = session['status'] as String? ?? 'waiting';
      final roundIndex = session['currentQuestionIndex'] as int? ?? 0;
      final questionIds =
      List<String>.from(session['questionIds'] as List? ?? []);

      // Build per-player state
      final playerStates = latestPlayers.map((p) {
        final uid = p['uid'] as String;
        return PlayerLiveState(
          uid: uid,
          username: p['username'] as String,
          isEliminated: p['isEliminated'] as bool? ?? false,
          hasAnsweredCurrentRound: latestAnsweredUids.contains(uid),
          lotteryTickets: p['lotteryTickets'] as int? ?? 0,
        );
      }).toList();

      // ── Phase resolution ───────────────────────────────────────────────

      SessionPhase phase;
      RoundResult? roundResult;

      switch (status) {
        case 'waiting':
          phase = SessionPhase.waiting;

        case 'finished':
          phase = SessionPhase.finished;

        default:
        // 'inProgress' — inspect the round document
          final roundStatus = latestRound?['status'] as String? ?? 'open';

          if (roundStatus == 'resolved') {
            phase = SessionPhase.resolving;

            final lotteryPool = List<String>.from(
                latestRound?['lotteryPool'] as List? ?? []);

            final eliminatedUid = latestRound?['eliminatedUid'] as String?;
            final eliminatedUsername = eliminatedUid == null
                ? null
                : playerStates
                .where((p) => p.uid == eliminatedUid)
                .firstOrNull
                ?.username;

            roundResult = RoundResult(
              eliminatedUid: eliminatedUid,
              eliminatedUsername: eliminatedUsername,
              lotteryOccurred:
              latestRound?['lotteryOccurred'] as bool? ?? false,
              lotteryPool: lotteryPool,
            );
          } else {
            phase = SessionPhase.answering;
          }
      }

      controller.add(LiveGameState(
        sessionId: sessionId,
        myUid: myUid,
        phase: phase,
        currentQuestionIndex: roundIndex,
        questionIds: questionIds,
        players: playerStates,
        answersSubmittedCount: latestAnswersCount,
        lastRoundResult: roundResult,
      ));
    }

    // ── Dynamic round subscription ─────────────────────────────────────────

    void subscribeToRound(int roundIndex) {
      roundSub?.cancel();
      answersSub?.cancel();
      latestRound = null;
      latestAnswersCount = 0;
      latestAnsweredUids = {};

      roundSub = _repo.roundStream(sessionId, roundIndex).listen(
            (data) {
          latestRound = data;
          tryEmit();
        },
        onError: controller.addError,
      );

      answersSub = _repo.answersStream(sessionId, roundIndex).listen(
            (data) {
          latestAnswersCount = data.count;
          latestAnsweredUids = data.answeredUids;
          tryEmit();
        },
        onError: controller.addError,
      );
    }

    // ── Static subscriptions ───────────────────────────────────────────────

    final sessionSub = _repo.sessionDocStream(sessionId).listen(
          (data) {
        latestSession = data;
        final roundIndex = data['currentQuestionIndex'] as int? ?? 0;
        if (roundIndex != subscribedRoundIndex) {
          subscribedRoundIndex = roundIndex;
          subscribeToRound(roundIndex);
        }
        tryEmit();
      },
      onError: controller.addError,
    );

    final playersSub = _repo.playersStream(sessionId).listen(
          (players) {
        latestPlayers = players;
        tryEmit();
      },
      onError: controller.addError,
    );

    // ── Cleanup ────────────────────────────────────────────────────────────

    controller.onCancel = () {
      sessionSub.cancel();
      playersSub.cancel();
      roundSub?.cancel();
      answersSub?.cancel();
    };

    return controller.stream;
  }

  @override
  Future<void> submitAnswer({
    required String sessionId,
    required String uid,
    required int roundIndex,
    required String questionId,
    required String answer,
  }) {
    return _repo.submitAnswer(
      sessionId: sessionId,
      uid: uid,
      roundIndex: roundIndex,
      questionId: questionId,
      answer: answer,
    );
  }

  @override
  Future<MultiplayerSessionData> fetchFinalSessionData(String sessionId) {
    return _repo.fetchArchivedSession(sessionId);
  }
}