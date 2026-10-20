import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:triviaapp/models/profile_data.dart';

class FirebaseAuthRepository {
  final FirebaseAuth _auth;

  FirebaseAuthRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

  /// Creates the account; AuthRegisterService completes the name and profile.
  Future<ProfileData> registerWithEmail(
      String email,
      String password,
      String username,
      ) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      return ProfileData(
        uid: credential.user!.uid,
        username: username
      );
    } on FirebaseAuthException catch (e) {
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('EMAIL: ${e.email}');
      debugPrint('CREDENTIAL: ${e.credential}');
      rethrow;
    }
  }

  Future<void> updateDisplayName(String uid, String username) async {
    final user = _auth.currentUser;
    if (user == null || user.uid != uid) {
      throw StateError('Registration user is no longer signed in');
    }
    await user.updateDisplayName(username);
  }

  Future<ProfileData> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    return ProfileData(uid: user.uid, username: user.displayName ?? '');
  }

  Future<void> signOut() => _auth.signOut();

  Stream<ProfileData?> authStateChanges() {
    return _auth.authStateChanges().map((user) {
      if (user == null) return null;
      return ProfileData(uid: user.uid, username: user.displayName ?? '');
    });
  }
}
