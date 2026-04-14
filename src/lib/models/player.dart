import 'package:flutter/foundation.dart';

@immutable
class Player {
  final String _uid;
  final String _username;

  const Player({
    required String uid,
    required String username,
  })  : _uid = uid,
        _username = username;

  factory Player.fromJson(Map<String, dynamic> json) {
    return Player(
      uid: json['uid'] as String,
      username: json['username'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uid': _uid,
      'username': _username,
    };
  }

  String get uid => _uid;
  String get username => _username;
}