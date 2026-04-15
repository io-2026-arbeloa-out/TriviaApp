import 'package:triviaapp/models/quiz.dart';

abstract class IQuizListService {
  Future<List<Quiz>> getQuizList();
}