import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  IconData getIcon() {
    switch (_category.toLowerCase()) {
      case 'general':
        return Icons.lightbulb;

      case 'history':
        return Icons.account_balance;

      case 'science':
        return Icons.science;

      case 'sports':
        return Icons.sports_soccer;

      case 'art_culture':
        return Icons.palette;

      case 'entertainment':
        return Icons.movie;

      default:
        return Icons.help_outline;
    }
  }

  String get category => _category;
  String get title => _title;
}