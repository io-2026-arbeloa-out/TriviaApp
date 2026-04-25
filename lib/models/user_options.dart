import 'package:flutter/foundation.dart';

@immutable
class UserOptions {
  final int _soundVolume;
  final int _musicVolume;
  final int _sfxVolume;

  const UserOptions({
    int soundVolume = 50,
    int musicVolume = 50,
    int sfxVolume = 50,
  }) :  _soundVolume = soundVolume,
        _musicVolume = musicVolume,
        _sfxVolume = sfxVolume;

  UserOptions copyWith({
    int? soundVolume,
    int? musicVolume,
    int? sfxVolume,
  }) {
    return UserOptions(
      soundVolume: soundVolume ?? this.soundVolume,
      musicVolume: musicVolume ?? this.musicVolume,
      sfxVolume: sfxVolume ?? this.sfxVolume,
    );
  }

  factory UserOptions.fromJson(Map<String, dynamic> json) {
    return UserOptions(
      soundVolume: json['soundVolume'] as int,
      musicVolume: json['musicVolume'] as int,
      sfxVolume: json['sfxVolume'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'soundVolume': _soundVolume,
      'musicVolume': _musicVolume,
      'sfxVolume': _sfxVolume,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserOptions &&
        other.soundVolume == soundVolume &&
        other.musicVolume == musicVolume &&
        other.sfxVolume == sfxVolume;
  }

  @override
  int get hashCode => Object.hash(soundVolume, musicVolume);

  int get soundVolume => _soundVolume;
  int get musicVolume => _musicVolume;
  int get sfxVolume => _sfxVolume;
}