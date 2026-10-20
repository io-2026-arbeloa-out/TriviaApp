import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/question.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';
import 'package:triviaapp/services/multiplayer_game_service.dart';

class _Questions extends Fake implements FirebaseQuestionRepository {
  bool called = false;

  @override
  Future<List<Question>> getQuestionsByIds({
    required String category,
    required List<String> ids,
  }) async {
    called = true;
    throw StateError('Question $category/${ids.first} not found');
  }
}

void main() {
  for (final ids in [
    <String>[],
    ['missing-question'],
  ]) {
    test('initialization rejects unavailable questions: $ids', () async {
      final db = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'player'),
        signedIn: true,
      );
      final questions = _Questions();
      await db.collection('users').doc('player').set({'username': 'Player'});
      await db.collection('sessions').doc('room').set({
        'categoryId': 'general',
        'questionIds': ids,
      });
      final service = MultiplayerGameService(
        sessionId: 'room',
        auth: auth,
        firestore: db,
        questionRepository: questions,
        sessionRepository: FirebaseSessionRepository(
          firestore: db,
        ),
      );

      await expectLater(service.ready, throwsStateError);
      expect(questions.called, ids.isNotEmpty);
    });
  }
}
