import 'package:triviaapp/models/quiz.dart';

abstract class QuizRepository {
  Future<List<Quiz>> getQuizList();
}
