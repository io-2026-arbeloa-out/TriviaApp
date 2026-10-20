import 'package:triviaapp/interfaces/i_register_auth_service.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/repositories/auth_repository.dart';
import 'package:triviaapp/repositories/profile_repository.dart';

class IncompleteRegistrationException implements Exception {
  final Object cause;

  const IncompleteRegistrationException(this.cause);
}

class AuthRegisterService implements IRegisterAuthService {
  final AuthRepository _authRepository;
  final ProfileRepository _profileRepository;
  // Keep the created account for retries in this service instance, not its password.
  ProfileData? _pendingProfile;
  String? _pendingEmail;

  AuthRegisterService({
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
  })  : _authRepository = authRepository,
        _profileRepository = profileRepository;

  @override
  Future<ProfileData> register(
      String email,
      String password,
      String username,
      ) async {
    if (_pendingProfile != null && email != _pendingEmail) {
      throw IncompleteRegistrationException(
        StateError('Complete registration for $_pendingEmail first'),
      );
    }
    if (_pendingProfile == null) {
      _pendingProfile = await _authRepository.registerWithEmail(
        email,
        password,
        username,
      );
      _pendingEmail = email;
    }
    final profileData = ProfileData(
      uid: _pendingProfile!.uid,
      username: username,
    );
    try {
      await _authRepository.updateDisplayName(profileData.uid, username);
      await _profileRepository.updateProfileData(profileData);
    } catch (e) {
      throw IncompleteRegistrationException(e);
    }
    _pendingProfile = null;
    _pendingEmail = null;
    return profileData;
  }

  @override
  Stream<ProfileData?> authStateChanges() {
    return _authRepository.authStateChanges();
  }
}
