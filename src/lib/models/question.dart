import 'package:flutter/foundation.dart';

@immutable
class Question {
  final String _id;
  final String _text;
  final Set<String> _correctAnswers;
  final Set<String>? _wrongAnswers;

  const Question({
    required String id,
    required String text,
    required Set<String> correctAnswers,
    Set<String>? wrongAnswers,
  })  : _id = id,
        _text = text,
        _correctAnswers = correctAnswers,
        _wrongAnswers = wrongAnswers;

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      text: json['text'] as String,
      correctAnswers: Set<String>.from(json['correctAnswers'] as List),
      wrongAnswers: Set<String>.from(json['wrongAnswers'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'correctAnswers': correctAnswers.toList(),
      'wrongAnswers': wrongAnswers?.toList(),
    };
  }

  String get id => _id;
  String get text => _text;
  Set<String> get correctAnswers => _correctAnswers;
  Set<String>? get wrongAnswers => _wrongAnswers;
}