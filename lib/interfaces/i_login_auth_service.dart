import 'package:triviaapp/models/profile_data.dart';

abstract class ILoginAuthService {
  Future<ProfileData> signInWithEmail(String email, String password);
  Future<void> signOut();
  Stream<ProfileData?> authStateChanges();
}