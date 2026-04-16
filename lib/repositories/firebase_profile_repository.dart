import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triviaapp/models/profile_data.dart';

class FirebaseProfileRepository {
  final FirebaseFirestore _firestore;

  FirebaseProfileRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<ProfileData> getProfileData(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();

    if (!doc.exists) {
      throw Exception('Profile not found for uid: $uid');
    }

    final data = doc.data()!;

    data['uid'] = uid;

    return ProfileData.fromJson(data);
  }

  Future<void> updateProfileData(ProfileData profileData) async {
    await _firestore
        .collection('users')
        .doc(profileData.uid)
        .set(
      profileData.toJson(),
      SetOptions(merge: true),
    );
  }

  Future<String> getUIPreset(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return 'default';
      return doc.data()!['ui_options'] as String? ?? 'default';
    } catch (e) {
      return 'default';
    }
  }
}