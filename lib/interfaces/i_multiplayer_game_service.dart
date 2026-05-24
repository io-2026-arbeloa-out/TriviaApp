import 'package:triviaapp/models/live_game_state.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/question.dart';

abstract class IMultiplayerGameService {
  String get sessionId;
  String get myUid;
  String get myUsername;
  List<Question> get questions;

  /// Single Firestore stream that emits [LiveGameState] on every meaningful
  /// document change. Implementations must await internal initialization
  /// before emitting the first event.
  Stream<LiveGameState> buildLiveGameStateStream();

  /// Writes the player's answer to Firestore.
  /// [sessionId] and [uid] are resolved internally by the implementation.
  Future<void> submitAnswer({
    required int roundIndex,
    required String questionId,
    required String answer,
  });

  /// Removes the player from the active session.
  /// Call when the user voluntarily leaves a game in progress.
  /// Fire-and-forget — the caller should swallow errors.
  Future<void> leaveGame();

  /// Fetches the final [MultiplayerSessionData] from sessions_archive.
  /// Call only after [LiveGameState.phase] == [SessionPhase.finished].
  Future<MultiplayerSessionData> fetchFinalSessionData();
}