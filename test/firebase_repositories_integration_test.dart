import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/models/session_data.dart';
import 'package:triviaapp/repositories/firebase_auth_repository.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';

void main() {
  group('Firebase repositories integration', () {
    test('FirebaseAuthRepository rejestruje i loguje użytkownika', () async {
      final repository = FirebaseAuthRepository();

      final profile = await repository.registerWithEmail(
        'integration@test.com',
        'secret123',
        'IntegrationUser',
      );

      expect(profile, isA<ProfileData>);

      final signedIn = await repository.signInWithEmail(
        'integration@test.com',
        'secret123',
      );

      expect(signedIn, isNotNull);
    });

    test('FirebaseSessionRepository tworzy i aktualizuje sesję multiplayer', () async {
      final repository = FirebaseSessionRepository();

      final session = await repository.createMultiplayerSession();
      expect(session, isA<SessionData>);

      await repository.updateSessionStatus(session.sessionId, 'FINISHED');

      expect(
        repository.getSessionStream(session.sessionId),
        emitsThrough(predicate((dynamic s) => s.status.toString().contains('FINISHED'))),
      );
    });

    test('FirebaseQuestionRepository zwraca oczekiwaną liczbę pytań', () async {
      final repository = FirebaseQuestionRepository();
      final questions = await repository.getQuestions(5, 1);

      expect(questions.length, 5);
    });
  });
}
