import 'package:triviaapp/interfaces/i_login_auth_service.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/repositories/firebase_auth_repository.dart';

class AuthLoginService implements ILoginAuthService {
  final FirebaseAuthRepository _authRepository;

  AuthLoginService({required FirebaseAuthRepository authRepository})
      : _authRepository = authRepository;

  @override
  Future<ProfileData> signInWithEmail(String email, String password) {
    return _authRepository.signInWithEmail(email, password);
  }

  @override
  Future<void> signOut() {
    return _authRepository.signOut();
  }

  @override
  Stream<ProfileData?> authStateChanges() {
    return _authRepository.authStateChanges();
  }
}