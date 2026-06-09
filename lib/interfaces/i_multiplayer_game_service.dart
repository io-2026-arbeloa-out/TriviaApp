import 'package:triviaapp/models/live_game_state.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/question.dart';

abstract class IMultiplayerGameService {
  String get sessionId;
  String get myUid;
  String get myUsername;
  List<Question> get questions;

  Stream<LiveGameState> buildLiveGameStateStream();
  Future<void> submitAnswer({
    required int roundIndex,
    required String questionId,
    required String answer,
  });

  Future<void> leaveGame();
  Future<MultiplayerSessionData> fetchFinalSessionData();
}