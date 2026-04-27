import 'dart:math';
import 'package:firebase_database/firebase_database.dart';
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
  }) async {
    final ref = _database.ref('$category/questions');
    final snapshot = await ref.get();

    if (!snapshot.exists || snapshot.value == null) return [];

    final List raw = snapshot.value as List;
    final random = Random();

    // zbierz indeksy pasujących pytań (bez pełnego mapowania na obiekty)
    final List<int> validIndexes = [];

    for (int i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item == null || item is! Map) continue;

      final value = Map<String, dynamic>.from(item);

      // szybki filtr po typie bez tworzenia obiektu Question
      final type = QuestionType.values.firstWhere(
            (e) => e.name == value['type'],
        orElse: () => QuestionType.values.first,
      );

      if (questionTypes.contains(type)) {
        validIndexes.add(i);
      }
    }

    if (validIndexes.isEmpty) return [];

    // losuj indeksy bez powtórzeń
    validIndexes.shuffle(random);
    final selectedIndexes = validIndexes.take(limit);

    final List<Question> questions = [];

    for (final i in selectedIndexes) {
      final value = Map<String, dynamic>.from(raw[i]);

      final question = Question.fromJson({
        'id': i.toString(),
        'category': category,
        ...value,
      });

      questions.add(question);
    }

    return questions;
  }
}