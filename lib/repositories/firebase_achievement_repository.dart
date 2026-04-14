import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:triviaapp/models/achievement.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/models/session_data.dart';

class FirebaseAchievementRepository {
  final FirebaseFirestore _firestore;

  FirebaseAchievementRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Załóżmy strukturę: profiles/{uid}/achievements/{achievementId}
  Future<List<Achievement>> getAchievements(
      ProfileData profileData,
      ) async {
    final query = await _firestore
        .collection('profiles')
        .doc(profileData.uid)
        .collection('achievements')
        .get();

    return query.docs
        .map((doc) => Achievement.fromJson(doc.data()))
        .toList();
  }

  /// Aktualizacja osiągnięć na podstawie wyniku gry.
  /// Konkretne reguły odblokowania zależą od logiki – tu szkic.
  Future<void> updateAchievements(
      ProfileData profileData,
      SessionData gameResult,
      ) async {
    final ref = _firestore
        .collection('profiles')
        .doc(profileData.uid)
        .collection('achievements');

    final batch = _firestore.batch();

    // Przykład – bardzo prosty, do rozszerzenia:
    // Odblokuj osiągnięcie „first_game” jeśli to pierwsza gra rankingowa.
    final achievementsSnap = await ref.get();
    final hasFirstGame = achievementsSnap.docs
        .any((d) => d.id == 'first_game');

    if (!hasFirstGame) {
      batch.set(
        ref.doc('first_game'),
        {
          'id': 'first_game',
          'name': 'Pierwsza gra',
          'description': 'Rozegraj swoją pierwszą grę.',
          'unlocked': true,
        },
      );
    }

    // Tu możesz dodać więcej reguł opartych o gameResult.

    await batch.commit();
  }
}