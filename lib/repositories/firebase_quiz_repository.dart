import 'package:firebase_database/firebase_database.dart';
import 'package:triviaapp/models/quiz.dart';

class FirebaseQuizRepository {
  final FirebaseDatabase _database;

  FirebaseQuizRepository({
    FirebaseDatabase? database,
  }) : _database = database ?? FirebaseDatabase.instance;

  Future<List<Quiz>> getQuizList() async {
    try {
      final ref = _database.ref('quizzes');
      final snapshot = await ref.get();

      if (!snapshot.exists || snapshot.value == null) return [];

      final rawData = snapshot.value;

      if (rawData is! Map) return [];

      final data = Map<String, dynamic>.from(rawData);

      return data.entries.map((entry) {
        final value = entry.value;

        if (value is! Map) return null;

        final quizData = Map<String, dynamic>.from(value);

        return Quiz.fromJson(quizData);
      }).whereType<Quiz>().toList();
    } catch (e, stack) {
      rethrow;
    }
  }
}