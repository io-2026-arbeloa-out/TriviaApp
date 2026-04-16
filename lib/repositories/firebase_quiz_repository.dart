import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triviaapp/models/quiz.dart';

class FirebaseQuizRepository {
  final FirebaseFirestore _firestore;

  FirebaseQuizRepository({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Quiz>> getQuizList() async {
    try {
      final snapshot = await _firestore.collection('quizzes').get();

      return snapshot.docs.map((doc) {
        return Quiz.fromJson(doc.data());
      }).toList();
    } catch (e, stack) {
      rethrow;
    }
  }
}