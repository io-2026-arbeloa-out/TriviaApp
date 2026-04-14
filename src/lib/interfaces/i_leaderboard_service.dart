import 'package:triviaapp/models/profile_data.dart';

abstract class ILeaderboardService {
  Future<List<ProfileData>> getLeaderboard();

  Future<int> getUserRank(String uid);
}