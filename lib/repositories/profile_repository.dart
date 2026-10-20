import 'package:triviaapp/models/profile_data.dart';

abstract class ProfileRepository {
  Future<ProfileData> getProfileData();
  Future<void> updateProfileData(ProfileData data);
  Future<String> getUIPreset();
}
