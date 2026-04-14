import 'package:triviaapp/models/profile_data.dart';

abstract class IProfileDataService {
  Future<ProfileData> getProfileData(String uid);

  Future<void> updateProfileData(ProfileData data);
}