import 'package:flutter/foundation.dart';

@immutable
class Quiz {
  final String _category;
  final String _title;

  const Quiz({
    required String category,
    required String title,
  })  : _category = category,
        _title = title;

  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      category: json['category'] as String,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category': _category,
      'title': _title,
    };
  }

  String get category => _category;
  String get title => _title;
}