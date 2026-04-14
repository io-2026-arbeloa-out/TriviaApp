import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triviaapp/models/profile_data.dart';

class FirebaseProfileRepository {
  final FirebaseFirestore _firestore;

  FirebaseProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<ProfileData> getProfileData(String uid) async {
    final snap =
    await _firestore.collection('profiles').doc(uid).get();

    if (!snap.exists) {
      throw StateError('Profile not found for uid: $uid');
    }

    return ProfileData.fromJson(snap.data()!);
  }

  Future<void> updateProfileData(ProfileData profileData) {
    return _firestore
        .collection('profiles')
        .doc(profileData.uid)
        .update(profileData.toJson());
  }
}