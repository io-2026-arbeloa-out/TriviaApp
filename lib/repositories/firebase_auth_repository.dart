import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:triviaapp/models/profile_data.dart';

class FirebaseAuthRepository {
  final FirebaseAuth _auth;

  FirebaseAuthRepository({FirebaseAuth? auth})
      : _auth = auth ?? FirebaseAuth.instance;

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
      await credential.user!.updateDisplayName(username);

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