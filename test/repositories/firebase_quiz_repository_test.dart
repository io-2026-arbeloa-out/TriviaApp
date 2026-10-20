import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/repositories/firebase_quiz_repository.dart';
import 'package:triviaapp/repositories/quiz_repository.dart';

void main() {
  test('the quiz repository returns stored categories and titles', () async {
    final db = FakeFirebaseFirestore();
    await db.collection('quizzes').doc('quiz').set({
      'category': 'history',
      'title': 'History',
    });
    final QuizRepository repo = FirebaseQuizRepository(firestore: db);
    final quizzes = await repo.getQuizList();
    expect(quizzes.single.category, 'history');
    expect(quizzes.single.title, 'History');
  });

  test('an empty collection is a successful empty quiz list', () async {
    expect(
      await FirebaseQuizRepository(
        firestore: FakeFirebaseFirestore(),
      ).getQuizList(),
      isEmpty,
    );
  });
}
