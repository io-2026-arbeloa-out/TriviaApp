import 'package:triviaapp/interfaces/i_achievement_service.dart';
import 'package:triviaapp/models/achievement.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/repositories/firebase_achievement_repository.dart';

class AchievementService implements IAchievementService {
  final FirebaseAchievementRepository _achievementRepository;

  AchievementService({
    FirebaseAchievementRepository? achievementRepository,
  }) :  _achievementRepository = achievementRepository ?? FirebaseAchievementRepository();

  @override
  Future<List<Achievement>> getAchievements(ProfileData profile) {
    return _achievementRepository.getAchievements(profile);
  }

  @override
  Future<void> updateAchievements(ProfileData profile) {
    // W repo metoda przyjmuje dodatkowo SessionData – musisz zdecydować,
    // czy przekazać rezultat ostatniej gry, czy uprościć interfejs.
    throw UnimplementedError('updateAchievements(ProfileData) wymaga SessionData w repo');
  }
}
