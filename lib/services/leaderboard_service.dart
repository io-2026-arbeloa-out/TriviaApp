import 'package:triviaapp/interfaces/i_leaderboard_service.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/repositories/firebase_leaderboard_repository.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';

class LeaderboardService implements ILeaderboardService {
  final FirebaseLeaderboardRepository _leaderboardRepository;
  final FirebaseProfileRepository _profileRepository;

  LeaderboardService(
      this._leaderboardRepository,
      this._profileRepository,
      );

  @override
  Future<List<ProfileData>> getLeaderboard() {
    // Diagram repo wymaga quizId, interfejs już nie – musisz zdecydować,
    // czy przekazywać quizId jako dodatkowy parametr.
    return _leaderboardRepository.getLeaderboard('default');
  }

  @override
  Future<int> getUserRank(String uid) async {
    // Możesz tu policzyć pozycję użytkownika w liście leaderboardu.
    final leaderboard = await getLeaderboard();
    final index = leaderboard.indexWhere((p) => p.uid == uid);
    return index == -1 ? -1 : index + 1;
  }
}