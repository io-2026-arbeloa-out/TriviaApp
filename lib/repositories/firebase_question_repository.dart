import 'package:firebase_database/firebase_database.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/question_type.dart';

///     {category}/
///       {questionId}/
///         text: "..."
///         correctAnswers: [...]
///         wrongAnswers: [...]
///         difficulty: "easy"
///         type: "open4"

class FirebaseQuestionRepository {
  final FirebaseDatabase _database;

  FirebaseQuestionRepository({FirebaseDatabase? database})
      : _database = database ?? FirebaseDatabase.instance;

  Future<List<Question>> getQuestions({
    required int limit,
    required String category,
    required List<QuestionType> questionTypes,
  }) async {
    final ref = _database.ref('$category');
    final snapshot = await ref.get();

    if (!snapshot.exists || snapshot.value == null) return [];

    final raw = Map<String, dynamic>.from(snapshot.value as Map);
    final List<Question> questions = [];
    final seenIds = <String>{};

    for (final entry in raw.entries) {
      final id = entry.key;
      final value = Map<String, dynamic>.from(entry.value as Map);

      final question = Question.fromJson({
        'id': id,
        'category': category,
        ...value,
      });

      if (questionTypes.contains(question.type) &&
          !seenIds.contains(id)) {
        seenIds.add(id);
        questions.add(question);
        if(questions.length >= limit) return questions;
      }
    }
    //do tej linii nigdy nie powinno dojść
    questions.shuffle();
    return questions.take(limit).toList();
  }
}