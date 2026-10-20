import 'package:triviaapp/models/live_game_state.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/game_answer.dart';

abstract class IMultiplayerGameService {
  String get sessionId;
  String get myUid;
  String get myUsername;
  List<Question> get questions;

  Stream<LiveGameState> buildLiveGameStateStream();
  Future<GameAnswer> submitAnswer({
    required int roundIndex,
    required String questionId,
    required String answer,
  });

  Future<void> leaveGame();
  Future<MultiplayerSessionData> fetchFinalSessionData();
}
