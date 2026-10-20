import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';

class _FailingFirestore extends Fake implements FirebaseFirestore {
  _FailingFirestore(this.error);
  final Object error;
  @override
  DocumentReference<Map<String, dynamic>> doc(String path) => throw error;
  @override
  CollectionReference<Map<String, dynamic>> collection(String path) => throw error;
}
void main() {
  for (final error in [FirebaseException(plugin: 'cloud_firestore', code: 'permission-denied'), Exception('Write failed')]) {
    test('profile update propagates ${error.runtimeType}', () async {
      final repository = FirebaseProfileRepository(firestore: _FailingFirestore(error), auth: MockFirebaseAuth());
      await expectLater(repository.updateProfileData(const ProfileData(uid: 'user', username: 'User')), throwsA(same(error)));
    });
  }
}
