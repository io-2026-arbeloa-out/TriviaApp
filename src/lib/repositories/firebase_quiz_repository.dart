import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triviaapp/models/quiz.dart';

class FirebaseQuizRepository {
  final FirebaseFirestore _firestore;

  FirebaseQuizRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Quiz>> getQuizList() async {
    final query = await _firestore.collection('quizzes').get();
    return query.docs.map((doc) {
      final data = doc.data();
      return Quiz.fromJson({
        'id': doc.id,
        ...data,
      });
    }).toList();
  }
}