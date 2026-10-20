import 'dart:math';
import 'package:triviaapp/interfaces/i_singleplayer_game_service.dart';
import 'package:triviaapp/models/game_answer.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';
import 'package:triviaapp/repositories/firebase_game_commands.dart';

class SingleplayerGameService implements ISingleplayerGameService {
  final FirebaseGameCommands _commands;
  final Random _random;
  String? _sessionId;
  List<String> _questionIds = [];

  SingleplayerGameService({FirebaseGameCommands? commands, Random? random})
      : _commands = commands ?? FirebaseGameCommands(), _random = random ?? Random();

  @override
  Future<List<Question>> loadQuestions(SingleplayerGameOptions options, String category) async {
    final data = await _commands.call('startSingleplayer', {
      'categoryId': category, 'count': options.numQuestions,
      'types': options.questionType.toList().map((t) => t.toJson()).toList(),
    });
    final questions = (data['questions'] as List)
        .map((q) => Question.fromJson(Map<String, dynamic>.from(q as Map))).toList();
    _sessionId = data['sessionId'] as String;
    _questionIds = questions.map((q) => q.id).toList();
    return questions;
  }

  @override
  List<String> getAnswerOptions(Question question) => question.answers.toList()..shuffle(_random);

  @override
  Future<GameAnswer> checkAnswer(Question question, String answer) async {
    final index = _questionIds.indexOf(question.id);
    if (_sessionId == null || index < 0) throw StateError('Question is not in this session');
    return GameAnswer.fromJson(await _commands.call('answerSingleplayer', {
      'sessionId': _sessionId, 'roundIndex': index, 'questionId': question.id, 'answer': answer,
    }));
  }
}
