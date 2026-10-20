import 'package:flutter/foundation.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/question_type.dart';

@immutable
class Question {
  final String id;
  final String text;
  final Set<String> answers;
  final QuestionType type;
  final Difficulty difficulty;

  const Question({required this.id, required this.text, required this.answers,
    required this.type, required this.difficulty});

  factory Question.fromJson(Map<String, dynamic> json) => Question(
    id: json['id'] as String, text: json['text'] as String,
    answers: Set<String>.from(json['answers'] as List),
    type: QuestionType.fromJson(json['type'] as String?),
    difficulty: Difficulty.fromJson(json['difficulty'] as String?),
  );

  Map<String, dynamic> toJson() => {'id': id, 'text': text, 'answers': answers.toList(),
    'type': type.name, 'difficulty': difficulty.name};
}
