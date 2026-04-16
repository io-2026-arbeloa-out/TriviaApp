import 'package:flutter/foundation.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/question_type.dart';

@immutable
class Question {
  final String _id;
  final String _text;
  final String _category;
  final Set<String> _correctAnswers;
  final Set<String>? _wrongAnswers;
  final QuestionType _type;
  final Difficulty _difficulty;

  const Question({
    required String id,
    required String text,
    required String category,
    required Set<String> correctAnswers,
    Set<String>? wrongAnswers,
    required QuestionType type,
    required Difficulty difficulty,
  })  : _difficulty = difficulty,
        _type = type,
        _id = id,
        _text = text,
        _category = category,
        _correctAnswers = correctAnswers,
        _wrongAnswers = wrongAnswers;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      category: json['category'] as String,
      correctAnswers: Set<String>.from(json['correctAnswers'] as List),
      wrongAnswers: Set<String>.from(json['wrongAnswers'] as List),
      type: QuestionType.fromJson(json['type'] as String?),
      difficulty: Difficulty.fromJson(json['difficulty'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'category': category,
      'correctAnswers': correctAnswers.toList(),
      'wrongAnswers': wrongAnswers?.toList(),
      'type': type.name,
      'difficulty': difficulty.name,
    };
  }

  String get id => _id;
  String get text => _text;
  String get category => _category;
  Set<String> get correctAnswers => _correctAnswers;
  Set<String>? get wrongAnswers => _wrongAnswers;
  Difficulty get difficulty => _difficulty;
  QuestionType get type => _type;
}