import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';

class _FailingFirestore extends Fake implements FirebaseFirestore {
  _FailingFirestore(this.error);
  final Object error;

  @override
  CollectionReference<Map<String, dynamic>> collection(String path) =>
      _FailingCollection(error);
}

// Firebase seals its reference types; these test doubles only inject write errors.
// ignore: subtype_of_sealed_class
class _FailingCollection extends Fake
    implements CollectionReference<Map<String, dynamic>> {
  _FailingCollection(this.error);
  final Object error;

  @override
  DocumentReference<Map<String, dynamic>> doc([String? path]) =>
      _FailingDocument(error);
}

// ignore: subtype_of_sealed_class
class _FailingDocument extends Fake
    implements DocumentReference<Map<String, dynamic>> {
  _FailingDocument(this.error);
  final Object error;

  @override
  Future<void> set(Map<String, dynamic> data, [SetOptions? options]) async {
    throw error;
  }
}

void main() {
  for (final error in [
    FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'),
    Exception('Write failed'),
  ]) {
    test('profile write propagates ${error.runtimeType}', () async {
      final repository = FirebaseProfileRepository(
        firestore: _FailingFirestore(error),
        auth: MockFirebaseAuth(),
      );

      await expectLater(
        repository.updateProfileData(
          const ProfileData(uid: 'user', username: 'User'),
        ),
        throwsA(same(error)),
      );
    });
  }
}
