//import 'package:your_app/models/achievement.dart';
import 'package:triviaapp/models/profile_data.dart';

abstract class IAchievementService {
  //Future<List<Achievement>> getAchievements(ProfileData profile);

  Future<void> updateAchievements(ProfileData profile);
}