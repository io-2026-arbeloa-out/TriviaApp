import 'package:flutter/foundation.dart';

@immutable
class Achievement {
  final String _aid;
  final String _title;
  final int _progression;

  const Achievement({
    required String aid,
    required String title,
    int progression = 0,
  })  : _aid = aid,
        _title = title,
        _progression = progression;

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      aid: json['aid'] as String,
      title: json['title'] as String,
      progression: (json['progression'] as int),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aid': _aid,
      'title': _title,
      'progression': _progression,
    };
  }

  String get aid => _aid;
  String get title => _title;
  int get progression => _progression;
}