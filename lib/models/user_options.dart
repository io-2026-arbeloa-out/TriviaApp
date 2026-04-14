import 'package:flutter/foundation.dart';

@immutable
class UserOptions {
  final int _soundVolume;
  final int _musicVolume;

  const UserOptions({
    int soundVolume = 50,
    int musicVolume = 50,
  }) :  _soundVolume = soundVolume,
        _musicVolume = musicVolume;

  UserOptions copyWith({
    int? soundVolume,
    int? musicVolume,
  }) {
    return UserOptions(
      soundVolume: soundVolume ?? this.soundVolume,
      musicVolume: musicVolume ?? this.musicVolume,
    );
  }

  factory UserOptions.fromJson(Map<String, dynamic> json) {
    return UserOptions(
      soundVolume: json['soundVolume'] as int,
      musicVolume: json['musicVolume'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soundVolume': _soundVolume,
      'musicVolume': _musicVolume,
    };
  }

  int get soundVolume => _soundVolume;
  int get musicVolume => _musicVolume;
}