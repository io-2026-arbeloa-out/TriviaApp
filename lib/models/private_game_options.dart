import 'package:flutter/foundation.dart';

@immutable
class PrivateGameOptions {
  final String _quizId;
  final int _maxPlayers;
  final int _entryCode;
  final int _questionTimeLimit;
  final String _quizCategory;

  const PrivateGameOptions({
    required String quizId,
    int maxPlayers = 10,
    required int entryCode,
    int questionTimeLimit = 30,
    String quizCategory = 'general',
  })  : _quizId = quizId,
        _maxPlayers = maxPlayers,
        _entryCode = entryCode,
        _questionTimeLimit = questionTimeLimit,
        _quizCategory = quizCategory;

  PrivateGameOptions copyWith({
    required String quizId,
    int? maxPlayers,
    required int entryCode,
    int? questionTimeLimit,
    String? quizCategory,
  }) {
    return PrivateGameOptions(
      quizId: this.quizId,
      maxPlayers: maxPlayers ?? _maxPlayers,
      entryCode: this.entryCode,
      questionTimeLimit: questionTimeLimit ?? _questionTimeLimit,
      quizCategory: quizCategory ?? _quizCategory,
    );
  }

  factory PrivateGameOptions.fromJson(Map<String, dynamic> json) {
    return PrivateGameOptions(
      quizId: json['quizId'] as String,
      maxPlayers: json['maxPlayers'] as int,
      entryCode: json['entryCode'] as int,
      questionTimeLimit: json['questionTimeLimit'] as int,
      quizCategory: json['quizCategory'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quizId': _quizId,
      'maxPlayers': _maxPlayers,
      'entryCode': _entryCode,
      'questionTimeLimit': _questionTimeLimit,
      'quizCategory': _quizCategory,
    };
  }

  String get quizId => _quizId;
  int get maxPlayers => _maxPlayers;
  int get entryCode => _entryCode;
  int get questionTimeLimit => _questionTimeLimit;
  String get quizCategory => _quizCategory;
}