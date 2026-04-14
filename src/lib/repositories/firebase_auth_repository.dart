import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:triviaapp/models/profile_data.dart';

class FirebaseAuthRepository {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  FirebaseAuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  /// Rejestracja użytkownika + utworzenie dokumentu profilu.
  Future<ProfileData> registerWithEmail(
      String email,
      String password,
      String displayName,
      ) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;
    await user.updateDisplayName(displayName);

    final profile = ProfileData(
      uid: user.uid,
      username: displayName,
      totalQuestionsAnswered: 0,
      correctAnswers: 0,
      rank: 'Newbie',
      ratingPoints: 0,
      rankedGamesPlayed: 0,
      rankedGamesWon: 0,
    );

    await _firestore
        .collection('profiles')
        .doc(user.uid)
        .set(profile.toJson());

    return profile;
  }

  /// Logowanie i pobranie istniejącego profilu.
  Future<ProfileData> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = credential.user!;
    final snap =
    await _firestore.collection('profiles').doc(user.uid).get();

    if (!snap.exists) {
      // Jeżeli profil nie istnieje – utwórz podstawowy.
      final profile = ProfileData(
        uid: user.uid,
        username: user.displayName ?? '',
        totalQuestionsAnswered: 0,
        correctAnswers: 0,
        rank: 'Newbie',
        ratingPoints: 0,
        rankedGamesPlayed: 0,
        rankedGamesWon: 0,
      );
      await _firestore
          .collection('profiles')
          .doc(user.uid)
          .set(profile.toJson());
      return profile;
    }

    return ProfileData.fromJson(snap.data()!);
  }

  Future<void> signOut() {
    return _auth.signOut();
  }

  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }
}