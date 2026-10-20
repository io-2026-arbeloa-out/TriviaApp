import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/controllers/controller_timer.dart';
import 'package:triviaapp/interfaces/i_multiplayer_game_service.dart';
import 'package:triviaapp/interfaces/i_singleplayer_game_service.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/game_answer.dart';
import 'package:triviaapp/models/live_game_state.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/question_type.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';
import 'session_fixtures.dart';

List<Question> gameQuestions() => [
  for (final id in ['0', '1', '2'])
    Question(
      id: id,
      text: 'Question $id?',
      answers: {'A', 'B'},
      type: QuestionType.open4,
      difficulty: Difficulty.easy,
    ),
];

class ManualClock {
  Duration elapsed = Duration.zero;
  final List<({Duration due, void Function() run, bool Function() active})>
  _tasks = [];
  CancelTimer schedule(Duration delay, void Function() callback) {
    bool active = true;
    _tasks.add((
      due: elapsed + delay,
      run: () {
        active = false;
        callback();
      },
      active: () => active,
    ));
    return () {
      active = false;
    };
  }

  void advance(Duration delta) {
    final end = elapsed + delta;
    while (true) {
      final due = _tasks.where((t) => t.active() && t.due <= end).toList()
        ..sort((a, b) => a.due.compareTo(b.due));
      if (due.isEmpty) break;
      elapsed = due.first.due;
      due.first.run();
    }
    elapsed = end;
  }

  int get pending => _tasks.where((t) => t.active()).length;
}

class SingleplayerServiceFake extends Fake implements ISingleplayerGameService {
  Completer<List<Question>>? loading;
  List<Question> loadedQuestions = gameQuestions();
  final submitted = <String>[];
  final answers = <Completer<GameAnswer>>[];
  @override
  Future<List<Question>> loadQuestions(
    SingleplayerGameOptions options,
    String category,
  ) async => loading == null ? loadedQuestions : await loading!.future;
  @override
  List<String> getAnswerOptions(Question question) => question.answers.toList();
  @override
  Future<GameAnswer> checkAnswer(Question question, String answer) {
    submitted.add(answer);
    final pending = Completer<GameAnswer>();
    answers.add(pending);
    return pending.future;
  }
}

class MultiplayerServiceFake extends Fake implements IMultiplayerGameService {
  final updates = StreamController<LiveGameState>.broadcast();
  LiveGameState? latest;
  int connections = 0, archiveCalls = 0, leaveCalls = 0;
  final submitted = <({int round, String id, String answer})>[];
  final answers = <Completer<GameAnswer>>[];
  Future<MultiplayerSessionData> Function()? readArchive;
  @override
  String get sessionId => 'room';
  @override
  String get myUid => 'uid1';
  @override
  String get myUsername => 'Player';
  @override
  List<Question> get questions => gameQuestions();
  @override
  Stream<LiveGameState> buildLiveGameStateStream() async* {
    connections++;
    if (latest != null) yield latest!;
    yield* updates.stream;
  }

  void emit(LiveGameState state) {
    latest = state;
    updates.add(state);
  }

  @override
  Future<GameAnswer> submitAnswer({
    required int roundIndex,
    required String questionId,
    required String answer,
  }) {
    submitted.add((round: roundIndex, id: questionId, answer: answer));
    final pending = Completer<GameAnswer>();
    answers.add(pending);
    return pending.future;
  }

  @override
  Future<MultiplayerSessionData> fetchFinalSessionData() async {
    archiveCalls++;
    return readArchive == null
        ? MultiplayerSessionData.fromJson(archiveDocument())
        : await readArchive!();
  }

  @override
  Future<void> leaveGame() async {
    leaveCalls++;
  }
}
