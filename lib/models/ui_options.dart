import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

@immutable
class UIOptions {
  final Color _mainColor;
  final Color _secondaryColor;
  final Color _mainButtonColor;
  final Color _secondaryButtonColor;
  final Color _textColor;

  const UIOptions({
    Color mainColor = const Color(0xFF0D47A1),
    Color secondaryColor = const Color(0xFF4A148C),
    Color mainButtonColor = Colors.green,
    Color secondaryButtonColor = Colors.white,
    Color textColor = Colors.white,
  })  : _mainColor = mainColor,
        _secondaryColor = secondaryColor,
        _mainButtonColor = mainButtonColor,
        _secondaryButtonColor = secondaryButtonColor,
        _textColor = textColor;

  UIOptions copyWith({
    Color? mainColor,
    Color? secondaryColor,
    Color? mainButtonColor,
    Color? secondaryButtonColor,
    Color? textColor
  }) {
    return UIOptions(
      mainColor: mainColor ?? this.mainColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      mainButtonColor: mainButtonColor ?? this.mainButtonColor,
      secondaryButtonColor: secondaryButtonColor ?? this.secondaryButtonColor,
      textColor: textColor ?? this.textColor,
    );
  }

  static Color _colorFromHex(String hex) {
    final buffer = StringBuffer();
    if (hex.length == 7) buffer.write('ff');
    buffer.write(hex.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  factory UIOptions.fromJson(Map<String, dynamic> json) {
    return UIOptions(
      mainColor: _colorFromHex(json['mainColor'] as String),
      secondaryColor: _colorFromHex(json['secondaryColor'] as String),
      mainButtonColor: _colorFromHex(json['mainButtonColor'] as String),
      secondaryButtonColor: _colorFromHex(json['secondaryButtonColor'] as String),
      textColor: _colorFromHex(json['textColor'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mainColor': _mainColor,
      'secondaryColor': _secondaryColor,
      'mainButtonColor' : _mainButtonColor,
      'secondaryButtonColor' : _secondaryButtonColor,
      'textColor' : _textColor
    };
  }

  Color get mainColor => _mainColor;
  Color get secondaryColor => _secondaryColor;
  Color get mainButtonColor => _mainButtonColor;
  Color get secondaryButtonColor => _secondaryButtonColor;
  Color get textColor => _textColor;
}
