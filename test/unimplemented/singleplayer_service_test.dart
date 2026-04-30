/*
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';
import 'package:triviaapp/services/singleplayer_game_service.dart';

class MockFirebaseSessionRepository extends Mock implements FirebaseSessionRepository {}
class MockFirebaseQuestionRepository extends Mock implements FirebaseQuestionRepository {}
class FakeQuestion extends Fake implements Question {}
class FakeSessionData extends Fake implements SessionData {}

void main() {
  late MockFirebaseSessionRepository sessionRepository;
  late MockFirebaseQuestionRepository questionRepository;
  late SingleplayerGameService service;

  setUpAll(() {
    registerFallbackValue(FakeQuestion());
    registerFallbackValue(FakeSessionData());
  });

  setUp(() {
    sessionRepository = MockFirebaseSessionRepository();
    questionRepository = MockFirebaseQuestionRepository();
    service = SingleplayerGameService(sessionRepository, questionRepository);
  });

  test('startGame tworzy sesję i pobiera pytania', () async {
    final session = FakeSessionData();
    final question = FakeQuestion();

    when(() => sessionRepository.createSession(any())).thenAnswer((_) async => session);
    when(() => questionRepository.getQuestions(any(), any())).thenAnswer((_) async => [question]);

    final result = await service.startGame({'limit': 1, 'category_id': 'general'});

    expect(result, isNotNull);
    verify(() => sessionRepository.createSession(any())).called(1);
    verify(() => questionRepository.getQuestions(any(), any())).called(1);
  });

  test('endGame ustawia status FINISHED w sesji', () async {
    final session = FakeSessionData();

    when(() => sessionRepository.updateSessionStatus(any(), any()))
        .thenAnswer((_) async => Future.value());

    await service.endGame(session);

    verify(() => sessionRepository.updateSessionStatus(any(), any())).called(1);
  });
}
*/
void main() {}