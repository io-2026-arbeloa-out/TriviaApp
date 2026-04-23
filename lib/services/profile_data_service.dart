import 'package:triviaapp/interfaces/i_profile_data_service.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';

class ProfileDataService implements IProfileDataService {
  final FirebaseProfileRepository _profileRepository;

  ProfileDataService(
      FirebaseProfileRepository? profileRepository,
      ) : _profileRepository = profileRepository ?? FirebaseProfileRepository();

  @override
  Future<ProfileData> getProfileData() {
    return _profileRepository.getProfileData();
  }

  @override
  Future<void> updateProfileData(ProfileData data) {
    return _profileRepository.updateProfileData(data);
  }
}