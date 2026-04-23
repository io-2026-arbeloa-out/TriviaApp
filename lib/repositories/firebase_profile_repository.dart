import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triviaapp/models/profile_data.dart';

class FirebaseProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseProfileRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User is not logged in');
    }
    return user.uid;
  }

  Future<ProfileData> getProfileData() async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('Profile not found for uid: $uid');
    return ProfileData.fromJson(uid, doc.data()!);
  }

  Future<void> updateProfileData(ProfileData profileData) async {
    try {
      await _firestore
          .collection('users')
          .doc(profileData.uid)
          .set(profileData.toJson(), SetOptions(merge: true));
    } on FirebaseException catch (e) {
      print('Firestore error: ${e.message}');
    } catch (e) {
      print('Unexpected error: $e');
    }
  }

  Future<String> getUIPreset() async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists || doc.data() == null) return 'default';
      return doc.data()!['ui_options'] as String? ?? 'default';
    } catch (e) {
      return 'default';
    }
  }
}