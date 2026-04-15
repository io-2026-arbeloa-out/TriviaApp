import 'package:triviaapp/models/game_mode.dart';
import 'package:triviaapp/models/player.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/session_status.dart';
import 'package:flutter/foundation.dart';

@immutable
class SessionData {
  final String _sessionId;
  final int _numPlayers;
  final SessionStatus _status;
  final DateTime _sessionStartTime;
  final DateTime _gameStartTime;
  final DateTime _endTime;
  final List<Player> _players;
  final List<int> _placement;
  final List<Question> _questions;
  final GameMode _gameMode;


  const SessionData({
    required String sessionId,
    required int numPlayers,
    required SessionStatus status,
    required DateTime sessionStartTime,
    required DateTime gameStartTime,
    required DateTime endTime,
    required List<Player> players,
    required List<int> placement,
    required List<Question> questions,
    required GameMode gameMode,
  })  : _sessionId = sessionId,
        _numPlayers = numPlayers,
        _status = status,
        _sessionStartTime = sessionStartTime,
        _gameStartTime = gameStartTime,
        _endTime = endTime,
        _players = players,
        _placement = placement,
        _questions = questions,
        _gameMode = gameMode;

  SessionData copyWith({
    SessionStatus? status,
    DateTime? gameStartTime,
    DateTime? endTime,
    List<Player>? players,
    List<int>? placement,
  }) {
    return SessionData(
      sessionId: sessionId,
      numPlayers: numPlayers,
      sessionStartTime: sessionStartTime,
      questions: questions,
      gameMode: gameMode,
      status: status ?? this.status,
      gameStartTime: gameStartTime ?? this.gameStartTime,
      endTime: endTime ?? this.endTime,
      players: players ?? this.players,
      placement: placement ?? this.placement,
    );
  }

  factory SessionData.fromJson(Map<String, dynamic> json) {
    return SessionData(
      sessionId: json['sessionId'] as String,
      numPlayers: json['numPlayers'] as int,
      status: SessionStatus.values.firstWhere(
            (e) => e.name == (json['status'] as String),
        orElse: () => SessionStatus.inProgress,
      ),
      sessionStartTime: DateTime.parse(json['sessionStartTime'] as String),
      gameStartTime: DateTime.parse(json['gameStartTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      players: (json['players'] as List<dynamic>)
          .map((e) => Player.fromJson(e as Map<String, dynamic>))
          .toList(),
      placement: List<int>.from(json['placement'] as List<dynamic>),
      questions: (json['questions'] as List<dynamic>)
          .map((e) => Question.fromJson(e as Map<String, dynamic>))
          .toList(),
      gameMode: GameMode.fromJson(json['gameMode'] as String?),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': _sessionId,
      'numPlayers': _numPlayers,
      'status': _status.name,
      'sessionStartTime': _sessionStartTime.toIso8601String(),
      'gameStartTime': _gameStartTime.toIso8601String(),
      'endTime': _endTime.toIso8601String(),
      'players': _players.map((p) => p.toJson()).toList(),
      'placement': _placement,
      'questions': _questions.map((q) => q.toJson()).toList(),
      'gameMode': _gameMode.name,
    };
  }

  String get sessionId => _sessionId;
  int get numPlayers => _numPlayers;
  SessionStatus get status => _status;
  DateTime get sessionStartTime => _sessionStartTime;
  DateTime get gameStartTime => _gameStartTime;
  DateTime get endTime => _endTime;
  List<Player> get players => _players;
  List<int> get placement => _placement;
  List<Question> get questions => _questions;
  GameMode get gameMode => _gameMode;
}