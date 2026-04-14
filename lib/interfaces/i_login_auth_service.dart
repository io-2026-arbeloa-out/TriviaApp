abstract class ILoginAuthService {
  Future<void> signInWithEmail(String email, String password);

  Future<void> signOut();

  Stream<dynamic> authStateChanges();
}