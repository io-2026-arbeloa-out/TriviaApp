import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/firebase_quiz_repository.dart';
import 'package:triviaapp/services/question_service.dart';
import 'package:triviaapp/services/quiz_list_service.dart';

class MockFirebaseQuestionRepository extends Mock implements FirebaseQuestionRepository {}
class MockFirebaseQuizRepository extends Mock implements FirebaseQuizRepository {}

void main() {
  test('QuestionService pobiera pytania z repozytorium', () async {
    final repo = MockFirebaseQuestionRepository();
    final service = QuestionService();

    when(() => repo.getQuestions(10, any())).thenAnswer((_) async => []);

    final result = await service.getQuestions(10, 'general');

    expect(result, isA<List>());
    verify(() => repo.getQuestions(10, any())).called(1);
  });

  test('QuizListService pobiera listę quizów', () async {
    final repo = MockFirebaseQuizRepository();
    final service = QuizListService();

    when(() => repo.getQuizList()).thenAnswer((_) async => []);

    final result = await service.getQuizList();

    expect(result, isA<List>());
    verify(() => repo.getQuizList()).called(1);
  });
}


