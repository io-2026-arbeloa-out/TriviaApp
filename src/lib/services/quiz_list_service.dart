import 'package:triviaapp/interfaces/i_quiz_list_service.dart';
import 'package:triviaapp/models/quiz.dart';
import 'package:triviaapp/repositories/firebase_quiz_repository.dart';

class QuizListService implements IQuizListService {
  final FirebaseQuizRepository _quizRepository;

  QuizListService(this._quizRepository);

  @override
  Future<List<Quiz>> getQuizList() {
    return _quizRepository.getQuizList();
  }
}