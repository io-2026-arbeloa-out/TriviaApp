import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/question_type.dart';

class FirebaseQuestionRepository {
  final FirebaseDatabase _database;

  FirebaseQuestionRepository({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  Future<List<Question>> getQuestions({
    required int limit,
    required String category,
    required List<QuestionType> questionTypes,
    required Difficulty difficulty,
  }) async {
    final ref = _database.ref('$category/questions');
    final snapshot = await ref.get();

    if (!snapshot.exists || snapshot.value == null) return [];

    final List raw = snapshot.value as List;
    final random = Random();

    final List<int> validIndexes = [];

    for (int i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item == null || item is! Map) continue;

      final value = Map<String, dynamic>.from(item);

      final type = QuestionType.values.firstWhere(
            (e) => e.name == value['type'],
        orElse: () => QuestionType.values.first,
      );

      if (!questionTypes.contains(type)) continue;
      if (difficulty != Difficulty.random && value['difficulty'] != difficulty.name) continue;

      validIndexes.add(i);
    }

    if (validIndexes.isEmpty) return [];

    validIndexes.shuffle(random);
    final selectedIndexes = validIndexes.take(limit);

    final List<Question> questions = [];

    for (final i in selectedIndexes) {
      final value = Map<String, dynamic>.from(raw[i]);
      questions.add(Question.fromJson({
        'id': i.toString(),
        'category': category,
        ...value,
      }));
    }

    return questions;
  }

  /// Fetches specific questions by their index-based IDs.
  /// IDs are the string-encoded array indices stored in the session's
  /// [questionIds] field. Preserves the original [ids] ordering.
  Future<List<Question>> getQuestionsByIds({
    required String category,
    required List<String> ids,
  }) async {
    if (ids.isEmpty) return [];

    final ref = _database.ref('$category/questions');
    final snapshot = await ref.get();

    if (!snapshot.exists || snapshot.value == null) return [];

    final List raw = snapshot.value as List;
    final questions = <Question>[];

    for (final id in ids) {
      final index = int.tryParse(id);
      if (index == null || index >= raw.length || raw[index] == null) continue;

      final item = raw[index];
      if (item is! Map) continue;

      final value = Map<String, dynamic>.from(item);
      questions.add(Question.fromJson({
        'id': id,
        'category': category,
        ...value,
      }));
    }

    return questions;
  }
}