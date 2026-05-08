import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/models/user_options.dart';

class FirebaseOptionsRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseOptionsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String get uid {
    final user = _auth.currentUser;
    if (user == null) throw StateError('User not logged in');
    return user.uid;
  }

  // ==== UserOptions ====

  Future<void> saveUserOptions(UserOptions options) {
    return _firestore
        .collection('users')
        .doc(uid)
        .set({'user_options': options.toJson()}, SetOptions(merge: true));
  }

  Future<UserOptions> getUserOptions() async {
    final snap = await _firestore.collection('users').doc(uid).get();
    if (!snap.exists) return UserOptions();
    return UserOptions.fromJson(snap.data()!['user_options']);
  }

  // ==== UIOptions ====

  Future<void> saveUIOptions(String preset) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .set({'ui_options': preset}, SetOptions(merge: true));
    } catch (e) {
      return Future.error('Failed to save UI options: $e');
    }
  }

  Future<UIOptions> getUIOptions(String preset) async {
    try {
      final snap = await _firestore.collection('ui_presets').doc(preset).get();
      if (!snap.exists || snap.data() == null) return UIOptions();
      return UIOptions.fromJson(snap.data()!);
    } catch (e) {
      return UIOptions();
    }
  }

  Future<Map<String, UIOptions>> getUIPresets() async {
    final snap = await _firestore.collection('ui_presets').get();
    final result = <String, UIOptions>{};
    for (final doc in snap.docs) {
      try {
        result[doc.id] = UIOptions.fromJson(doc.data());
      } catch (_) {}
    }
    return result;
  }
}