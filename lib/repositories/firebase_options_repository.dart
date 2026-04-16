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

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('User not logged in');
    }
    return user.uid;
  }

  // ==== UserOptions (dźwięk / muzyka) ====

  Future<void> saveUserOptions(UserOptions options) {
    return _firestore
        .collection('userOptions')
        .doc(_uid)
        .set(options.toJson(), SetOptions(merge: true));
  }

  Future<UserOptions> getUserOptions() async {
    final snap =
    await _firestore.collection('userOptions').doc(_uid).get();
    if (!snap.exists) {
      return const UserOptions(soundVolume: 50, musicVolume: 50);
    }
    return UserOptions.fromJson(snap.data()!);
  }

  // ==== UIOptions (kolory UI) ====

  Future<void> saveUIOptions(UIOptions options) {
    return _firestore
        .collection('uiOptions')
        .doc(_uid)
        .set(options.toJson(), SetOptions(merge: true));
  }

  Future<UIOptions> loadUIOptions(String preset) async {
    try {
      final snap = await _firestore.collection('ui_presets').doc(preset).get();
      if (!snap.exists || snap.data() == null) return const UIOptions();
      return UIOptions.fromJson(snap.data()!);
    } catch (e) {
      return const UIOptions();
    }
  }
}