import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triviaapp/models/question.dart';

class FirebaseQuestionRepository {
  final FirebaseFirestore _firestore;

  FirebaseQuestionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<List<Question>> getQuestions(int limit, int categoryID) async {
    final query = await _firestore
        .collection('questions')
        .where('categoryId', isEqualTo: categoryID)
        .limit(limit)
        .get();

    return query.docs
        .map((doc) => Question.fromJson(doc.data()))
        .toList();
  }
}