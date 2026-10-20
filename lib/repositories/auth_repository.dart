import 'package:triviaapp/models/profile_data.dart';

abstract class AuthRepository {
  bool get isSignedIn;
  ProfileData? get currentUser;
  Future<ProfileData> signInWithEmail(String email, String password);
  Future<ProfileData> registerWithEmail(
    String email,
    String password,
    String username,
  );
  Future<void> updateDisplayName(String uid, String username);
  Future<void> signOut();
  Stream<ProfileData?> authStateChanges();
}
