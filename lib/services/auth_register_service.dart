import 'package:triviaapp/interfaces/i_register_auth_service.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/repositories/firebase_auth_repository.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';

class AuthRegisterService implements IRegisterAuthService {
  final FirebaseAuthRepository _authRepository;
  final FirebaseProfileRepository _profileRepository;

  AuthRegisterService({
    required FirebaseAuthRepository authRepository,
    required FirebaseProfileRepository profileRepository,
  })  : _authRepository = authRepository,
        _profileRepository = profileRepository;

  @override
  Future<ProfileData> register(
      String email,
      String password,
      String username,
      ) async {
    final profileData = await _authRepository.registerWithEmail(
      email,
      password,
      username,
    );
    await _profileRepository.updateProfileData(profileData);
    return profileData;
  }

  @override
  Stream<ProfileData?> authStateChanges() {
    return _authRepository.authStateChanges();
  }
}