import 'package:triviaapp/interfaces/i_question_service.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';

class QuestionService implements IQuestionService {
  final FirebaseQuestionRepository _questionRepository;

  QuestionService(this._questionRepository);

  @override
  Future<List<Question>> getQuestions(int limit, int categoryID) {
    return _questionRepository.getQuestions(limit, categoryID);
  }
}