import 'package:flutter/foundation.dart';
import 'package:triviaapp/models/difficulty.dart';

@immutable
class OnlineGameOptions {
  final String _categoryId;
  final int _maxPlayers;
  final int _questionTimeLimit;
  final Difficulty _difficulty;

  /// Non-null for private games; null for public matchmaking.
  final int? _entryCode;

  const OnlineGameOptions({
    required String categoryId,
    int maxPlayers = 2,//todo 10
    int questionTimeLimit = 30,
    int? entryCode,
    Difficulty difficulty = Difficulty.medium,
  })  : _categoryId = categoryId,
        _maxPlayers = maxPlayers,
        _questionTimeLimit = questionTimeLimit,
        _entryCode = entryCode,
        _difficulty = difficulty;

  OnlineGameOptions copyWith({
    String? categoryId,
    int? maxPlayers,
    int? questionTimeLimit,
    int? entryCode,
    Difficulty? difficulty,
  }) {
    return OnlineGameOptions(
      categoryId: categoryId ?? _categoryId,
      maxPlayers: maxPlayers ?? _maxPlayers,
      questionTimeLimit: questionTimeLimit ?? _questionTimeLimit,
      entryCode: entryCode ?? _entryCode,
      difficulty: difficulty ?? _difficulty,
    );
  }

  String get categoryId => _categoryId;
  int get maxPlayers => _maxPlayers;
  int get questionTimeLimit => _questionTimeLimit;
  Difficulty get difficulty => _difficulty;
  int? get entryCode => _entryCode;

  bool get isPrivate => _entryCode != null;
}