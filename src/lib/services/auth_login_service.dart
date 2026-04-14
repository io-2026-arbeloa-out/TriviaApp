import 'package:triviaapp/interfaces/i_login_auth_service.dart';
import 'package:triviaapp/repositories/firebase_auth_repository.dart';

class AuthLoginService implements ILoginAuthService {
  final FirebaseAuthRepository _authRepository;

  AuthLoginService(this._authRepository);

  @override
  Future<void> signInWithEmail(String email, String password) {
    return _authRepository.signInWithEmail(email, password);
  }

  @override
  Future<void> signOut() {
    return _authRepository.signOut();
  }

  @override
  Stream authStateChanges() {
    return _authRepository.authStateChanges();
  }
}