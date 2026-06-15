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
    final ref = _database.ref('questions/$category');
    final snapshot = await ref.get();

    if (!snapshot.exists || snapshot.value == null) return [];

    final random = Random();
    final List<({String id, Map<String, dynamic> value})> validItems = [];

    for (final child in snapshot.children) {
      if (child.value == null || child.value is! Map) continue;

      final value = Map<String, dynamic>.from(child.value as Map);

      final type = QuestionType.values.firstWhere(
            (e) => e.name == value['type'],
        orElse: () => QuestionType.values.first,
      );

      if (!questionTypes.contains(type)) continue;
      if (difficulty != Difficulty.random &&
          value['difficulty'] != difficulty.name) continue;

      validItems.add((id: child.key!, value: value));
    }

    if (validItems.isEmpty) return [];

    validItems.shuffle(random);
    final selected = validItems.take(limit);

    return selected.map((item) {
      return Question.fromJson({
        'id': item.id,
        'category': category,
        ...item.value,
      });
    }).toList();
  }

  /// Fetches specific questions by their index-based IDs.
  /// IDs are the string-encoded array indices stored in the session's
  /// [questionIds] field. Preserves the original [ids] ordering.
  Future<List<Question>> getQuestionsByIds({
    required String category,
    required List<String> ids,
  }) async {
    if (ids.isEmpty) return [];

    final ref = _database.ref('questions/$category');
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