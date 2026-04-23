import 'package:flutter/foundation.dart';
import 'package:triviaapp/models/rank.dart';
import 'package:triviaapp/models/user_options.dart';

@immutable
class ProfileData {
  final String _uid;
  final String _username;
  final int _totalQuestionsAnswered;
  final int _correctAnswers;
  final Rank _rank;
  final int _ratingPoints;
  final int _rankedGamesPlayed;
  final int _rankedGamesWon;
  final UserOptions _userOptions;
  final String _uiPreset;

  const ProfileData({
    required String uid,
    required String username,
    int totalQuestionsAnswered = 0,
    int correctAnswers = 0,
    Rank rank = Rank.unranked,
    int ratingPoints = 0,
    int rankedGamesPlayed = 0,
    int rankedGamesWon = 0,
    UserOptions userOptions = const UserOptions(),
    String uiPreset = 'default',
  })  : _uid = uid,
        _username = username,
        _totalQuestionsAnswered = totalQuestionsAnswered,
        _correctAnswers = correctAnswers,
        _rank = rank,
        _ratingPoints = ratingPoints,
        _rankedGamesPlayed = rankedGamesPlayed,
        _rankedGamesWon = rankedGamesWon,
        _userOptions = userOptions,
        _uiPreset = uiPreset;

  ProfileData copyWith({
    int? totalQuestionsAnswered,
    int? correctAnswers,
    Rank? rank,
    int? ratingPoints,
    int? rankedGamesPlayed,
    int? rankedGamesWon,
    UserOptions? userOptions,
    String? uiPreset,
  }) {
    return ProfileData(
      uid: _uid,
      username: _username,
      totalQuestionsAnswered: totalQuestionsAnswered ?? _totalQuestionsAnswered,
      correctAnswers: correctAnswers ?? _correctAnswers,
      rank: rank ?? _rank,
      ratingPoints: ratingPoints ?? _ratingPoints,
      rankedGamesPlayed: rankedGamesPlayed ?? _rankedGamesPlayed,
      rankedGamesWon: rankedGamesWon ?? _rankedGamesWon,
      userOptions: userOptions ?? _userOptions,
      uiPreset: uiPreset ?? _uiPreset,
    );
  }

  factory ProfileData.fromJson(String uid, Map<String, dynamic> json) {
    final rawUserOptions = json['user_options'];
    final userOptions = rawUserOptions is Map<String, dynamic>
        ? UserOptions.fromJson(rawUserOptions)
        : const UserOptions();

    return ProfileData(
      uid: uid,
      username: json['username'] as String,
      totalQuestionsAnswered: (json['totalQuestionsAnswered'] as int?) ?? 0,
      correctAnswers: (json['correctAnswers'] as int?) ?? 0,
      rank: Rank.fromJson(json['rank'] as String?),
      ratingPoints: (json['ratingPoints'] as int?) ?? 0,
      rankedGamesPlayed: (json['rankedGamesPlayed'] as int?) ?? 0,
      rankedGamesWon: (json['rankedGamesWon'] as int?) ?? 0,
      userOptions: userOptions,
      uiPreset: (json['ui_options'] as String?) ?? 'default',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'username': _username,
      'totalQuestionsAnswered': _totalQuestionsAnswered,
      'correctAnswers': _correctAnswers,
      'rank': _rank.name,
      'ratingPoints': _ratingPoints,
      'rankedGamesPlayed': _rankedGamesPlayed,
      'rankedGamesWon': _rankedGamesWon,
      'user_options': _userOptions.toJson(),
      'ui_options': _uiPreset,
    };
  }

  String get uid => _uid;
  String get username => _username;
  int get totalQuestionsAnswered => _totalQuestionsAnswered;
  int get correctAnswers => _correctAnswers;
  Rank get rank => _rank;
  int get ratingPoints => _ratingPoints;
  int get rankedGamesPlayed => _rankedGamesPlayed;
  int get rankedGamesWon => _rankedGamesWon;
  UserOptions get userOptions => _userOptions;
  String get uiPreset => _uiPreset;
}