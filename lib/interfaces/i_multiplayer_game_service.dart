import 'package:triviaapp/models/live_game_state.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';

abstract class IMultiplayerGameService {
  /// Combines session doc, players subcollection, current round doc,
  /// and answers subcollection into a single [LiveGameState] stream.
  ///
  /// The stream automatically re-subscribes to the round document when
  /// [currentQuestionIndex] advances.
  Stream<LiveGameState> buildLiveGameStateStream({
    required String sessionId,
    required String myUid,
  });

  /// Writes the player's answer to Firestore.
  /// [isCorrect] is intentionally NOT set here — the Cloud Function sets it.
  Future<void> submitAnswer({
    required String sessionId,
    required String uid,
    required int roundIndex,
    required String questionId,
    required String answer,
  });

  /// Fetches the final [MultiplayerSessionData] from sessions_archive.
  /// Call only after [LiveGameState.phase] == [SessionPhase.finished].
  Future<MultiplayerSessionData> fetchFinalSessionData(String sessionId);
}