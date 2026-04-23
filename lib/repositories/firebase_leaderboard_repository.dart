import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triviaapp/models/profile_data.dart';

class FirebaseLeaderboardRepository {
  final FirebaseFirestore _firestore;

  FirebaseLeaderboardRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Zakładam strukturę:
  /// leaderboards/{quizId}/entries/{uid} -> pola jak w ProfileData + np. score.
  Future<List<ProfileData>> getLeaderboard(String quizId) async {
    final query = await _firestore
        .collection('leaderboards')
        .doc(quizId)
        .collection('entries')
        .orderBy('ratingPoints', descending: true)
        .get();

    return query.docs
        .map((doc) => ProfileData.fromJson('uid1', doc.data()))
        .toList();
  }
}