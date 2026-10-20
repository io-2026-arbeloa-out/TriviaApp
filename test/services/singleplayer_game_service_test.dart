import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';
import 'package:triviaapp/repositories/firebase_game_commands.dart';
import 'package:triviaapp/services/singleplayer_game_service.dart';

final question = {'id': 'q', 'text': 'Question?', 'answers': ['A', 'B'], 'type': 'open4', 'difficulty': 'easy'};
class _Commands extends Fake implements FirebaseGameCommands {
  Map<String, dynamic>? lastData;
  @override
  Future<Map<String, dynamic>> call(String name, Map<String, dynamic> data) async {
    lastData = data;
    return name == 'startSingleplayer'
        ? {'sessionId': 'issued-session', 'questions': [question]}
        : {'isCorrect': false, 'correctAnswers': ['B']};
  }
}
void main() {
  test('uses the issued session and server feedback, not local answer labels', () async {
    final commands = _Commands();
    final service = SingleplayerGameService(commands: commands);
    final questions = await service.loadQuestions(const SingleplayerGameOptions(), 'general');
    expect(questions.single.toJson().containsKey('correctAnswers'), isFalse);
    expect(service.getAnswerOptions(questions.single).toSet(), {'A', 'B'});
    final answer = await service.checkAnswer(questions.single, 'A');
    expect(answer.isCorrect, isFalse); expect(answer.correctAnswers, ['B']);
    expect(commands.lastData, {'sessionId': 'issued-session', 'roundIndex': 0, 'questionId': 'q', 'answer': 'A'});
  });
  test('does not validate a question before starting a session', () async {
    final commands = _Commands();
    await expectLater(SingleplayerGameService(commands: commands).checkAnswer(Question.fromJson(question), 'A'), throwsStateError);
    expect(commands.lastData, isNull);
  });
}
