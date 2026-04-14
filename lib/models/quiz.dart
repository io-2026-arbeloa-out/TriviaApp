import 'package:flutter/foundation.dart';

@immutable
class Quiz {
  final String _qid;
  final String _title;
  final String _fileName;

  const Quiz({
    required String qid,
    required String title,
    required String fileName,
  })  : _qid = qid,
        _title = title,
        _fileName = fileName;


  factory Quiz.fromJson(Map<String, dynamic> json) {
    return Quiz(
      qid: json['qid'] as String,
      title: json['title'] as String,
      fileName: json['fileName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'qid': _qid,
      'title': _title,
      'fileName': _fileName,
    };
  }

  String get qid => _qid;
  String get title => _title;
  String get fileName => _fileName;
}