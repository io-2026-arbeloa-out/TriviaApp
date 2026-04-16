import 'package:triviaapp/models/profile_data.dart';

abstract class IRegisterAuthService {
  Future<ProfileData> register(String email, String password, String username);
  Stream<ProfileData?> authStateChanges();
}