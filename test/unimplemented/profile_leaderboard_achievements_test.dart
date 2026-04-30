/*
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/repositories/firebase_achievement_repository.dart';
import 'package:triviaapp/repositories/firebase_leaderboard_repository.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';
import 'package:triviaapp/services/achievements_service.dart';
import 'package:triviaapp/services/leaderboard_service.dart';
import 'package:triviaapp/services/profile_data_service.dart';

class MockFirebaseProfileRepository extends Mock implements FirebaseProfileRepository {}
class MockFirebaseLeaderboardRepository extends Mock implements FirebaseLeaderboardRepository {}
class MockFirebaseAchievementRepository extends Mock implements FirebaseAchievementRepository {}
class FakeProfileData extends Fake implements ProfileData {}
class FakeSessionData extends Fake implements SessionData {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeProfileData());
    registerFallbackValue(FakeSessionData());
  });

  test('ProfileDataService pobiera profil użytkownika', () async {
    final repo = MockFirebaseProfileRepository();
    final service = ProfileDataService(repo);
    final profile = FakeProfileData();

    when(() => repo.getProfileData('uid-1')).thenAnswer((_) async => profile);

    final result = await service.getProfileData('uid-1');

    expect(result, same(profile));
  });

  test('LeaderboardService pobiera ranking', () async {
    final leaderboardRepo = MockFirebaseLeaderboardRepository();
    final profileRepo = MockFirebaseProfileRepository();
    final service = LeaderboardService(leaderboardRepo, profileRepo);

    when(() => leaderboardRepo.getLeaderboard(any())).thenAnswer((_) async => []);

    final result = await service.getLeaderboard();

    expect(result, isA<List>());
  });

  test('AchievementService aktualizuje osiągnięcia na podstawie wyniku gry', () async {
    final repo = MockFirebaseAchievementRepository();
    final service = AchievementService(repo);

    when(() => repo.updateAchievements(any(), any())).thenAnswer((_) async => Future.value());

    await service.updateAchievements(FakeProfileData(), FakeSessionData());

    verify(() => repo.updateAchievements(any(), any())).called(1);
  });
}
*/
void main() {}