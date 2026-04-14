import 'package:triviaapp/models/question.dart';

abstract class IQuestionService {
  Future<List<Question>> getQuestions(int limit, int categoryID);
}