import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';

class QuestionService {
  final FirebaseQuestionRepository _questionRepository;

  QuestionService({
    FirebaseQuestionRepository? questionRepository
      })  : _questionRepository = questionRepository ?? FirebaseQuestionRepository();

  Future<List<Question>> getQuestions(int limit, String categoryID) async {
    return _questionRepository.getQuestions(limit, categoryID);
  }
}