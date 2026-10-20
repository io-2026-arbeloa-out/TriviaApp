import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triviaapp/models/quiz.dart';
import 'package:triviaapp/repositories/quiz_repository.dart';

class FirebaseQuizRepository implements QuizRepository {
  final FirebaseFirestore _firestore;

  FirebaseQuizRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<Quiz>> getQuizList() async {
    try {
      final snapshot = await _firestore.collection('quizzes').get();
      return snapshot.docs.map((doc) {
        return Quiz.fromJson(doc.data());
      }).toList();
    } catch (e) {
      print(e);
      rethrow;
    }
  }
}
