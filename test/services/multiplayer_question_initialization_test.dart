import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/app_dependencies.dart';
import 'package:triviaapp/models/profile_data.dart';
import '../support/session_fixtures.dart';

class _UnusedDatabase extends Fake implements FirebaseDatabase {}

void main() {
  test(
    'the game factory shares supplied Auth and Firestore with nested repositories',
    () async {
      final db = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: 'player'),
        signedIn: true,
      );
      await db
          .collection('users')
          .doc('player')
          .set(const ProfileData(uid: 'player', username: 'Player').toJson());
      await db
          .collection('sessions')
          .doc('room')
          .set(sessionDocument(status: 'waiting', ids: []));
      final deps = AppDependencies(
        auth: auth,
        firestore: db,
        database: _UnusedDatabase(),
      );
      await expectLater(
        deps.createMultiplayerGameService('room').ready,
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            'Session has no questions',
          ),
        ),
      );
    },
  );
}
