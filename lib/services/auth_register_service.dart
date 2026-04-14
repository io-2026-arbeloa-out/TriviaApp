import 'package:triviaapp/interfaces/i_register_auth_service.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/repositories/firebase_auth_repository.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';

class AuthRegisterService implements IRegisterAuthService {
  final FirebaseAuthRepository _authRepository;
  final FirebaseProfileRepository _profileRepository;

  AuthRegisterService(
      this._authRepository,
      this._profileRepository,
      );

  @override
  Future<void> register(String email, String password, String displayName) async {
    // Rejestracja w auth + utworzenie profilu
    final profile =
    await _authRepository.registerWithEmail(email, password, displayName);
    await _profileRepository.updateProfileData(profile);
  }

  @override
  Future<ProfileData> generateProfile() async {
    // Prosta implementacja – pobierz aktualny profil z repo
    // Możesz tu dodać logikę defaultowych wartości.
    throw UnimplementedError('generateProfile zależy od logiki aplikacji');
  }

  @override
  Stream authStateChanges() {
    return _authRepository.authStateChanges();
  }
}