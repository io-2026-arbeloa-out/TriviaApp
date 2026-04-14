import 'package:triviaapp/models/profile_data.dart';

abstract class IRegisterAuthService {
  Future<void> register(String email, String password, String displayName);

  Future<ProfileData> generateProfile();

  Stream<dynamic> authStateChanges();
}