import 'package:flutter/foundation.dart';
import 'package:triviaapp/models/rank.dart';

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

  const ProfileData({
    required String uid,
    required String username,
    int totalQuestionsAnswered = 0,
    int correctAnswers = 0,
    Rank rank = Rank.unranked,
    int ratingPoints = 0,
    int rankedGamesPlayed = 0,
    int rankedGamesWon = 0,
  })  : _uid = uid,
        _username = username,
        _totalQuestionsAnswered = totalQuestionsAnswered,
        _correctAnswers = correctAnswers,
        _rank = rank,
        _ratingPoints = ratingPoints,
        _rankedGamesPlayed = rankedGamesPlayed,
        _rankedGamesWon = rankedGamesWon;

  ProfileData copyWith({
    int? totalQuestionsAnswered,
    int? correctAnswers,
    Rank? rank,
    int? ratingPoints,
    int? rankedGamesPlayed,
    int? rankedGamesWon,
  }) {
    return ProfileData(
      uid: uid,
      username: username,
      totalQuestionsAnswered: totalQuestionsAnswered ?? _totalQuestionsAnswered,
      correctAnswers: correctAnswers ?? _correctAnswers,
      rank: rank ?? _rank,
      ratingPoints: ratingPoints ?? _ratingPoints,
      rankedGamesPlayed: rankedGamesPlayed ?? _rankedGamesPlayed,
      rankedGamesWon: rankedGamesWon ?? _rankedGamesWon,
    );
  }

  factory ProfileData.fromJson(Map<String, dynamic> json) {
    return ProfileData(
      uid: json['uid'] as String,
      username: json['username'] as String,
      totalQuestionsAnswered: json['totalQuestionsAnswered'] as int,
      correctAnswers: json['correctAnswers'] as int,
      rank: Rank.fromJson(json['rank'] as String?),
      ratingPoints: json['ratingPoints'] as int,
      rankedGamesPlayed: json['rankedGamesPlayed'] as int,
      rankedGamesWon: json['rankedGamesWon'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': _uid,
      'username': _username,
      'totalQuestionsAnswered': _totalQuestionsAnswered,
      'correctAnswers': _correctAnswers,
      'rank': _rank.name,
      'ratingPoints': _ratingPoints,
      'rankedGamesPlayed': _rankedGamesPlayed,
      'rankedGamesWon': _rankedGamesWon,
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
}