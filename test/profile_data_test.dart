import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/models/rank.dart';

void main() {
  group('ProfileData', () {
    group('constructor defaults', () {
      test('sets numeric fields to 0 when not provided', () {
        final profile = ProfileData(uid: 'u1', username: 'Alice');

        expect(profile.totalQuestionsAnswered, 0);
        expect(profile.correctAnswers, 0);
        expect(profile.ratingPoints, 0);
        expect(profile.rankedGamesPlayed, 0);
        expect(profile.rankedGamesWon, 0);
      });

      test('sets rank to Rank.unranked when not provided', () {
        final profile = ProfileData(uid: 'u1', username: 'Alice');
        expect(profile.rank, Rank.unranked);
      });

      test('stores uid and username exactly as provided', () {
        final profile = ProfileData(uid: 'abc-123', username: 'Bob');
        expect(profile.uid, 'abc-123');
        expect(profile.username, 'Bob');
      });
    });

    group('fromJson', () {
      test('maps all fields correctly from a complete JSON', () {
        final json = {
          'uid': 'uid-42',
          'username': 'Alice',
          'totalQuestionsAnswered': 50,
          'correctAnswers': 30,
          'rank': 'gold',
          'ratingPoints': 1200,
          'rankedGamesPlayed': 10,
          'rankedGamesWon': 6,
        };

        final profile = ProfileData.fromJson(json);

        expect(profile.uid, 'uid-42');
        expect(profile.username, 'Alice');
        expect(profile.totalQuestionsAnswered, 50);
        expect(profile.correctAnswers, 30);
        expect(profile.rank, Rank.gold);
        expect(profile.ratingPoints, 1200);
        expect(profile.rankedGamesPlayed, 10);
        expect(profile.rankedGamesWon, 6);
      });

      test('handles null rank by defaulting to unranked', () {
        final json = {
          'uid': 'uid-1',
          'username': 'Test',
          'totalQuestionsAnswered': 0,
          'correctAnswers': 0,
          'rank': null,
          'ratingPoints': 0,
          'rankedGamesPlayed': 0,
          'rankedGamesWon': 0,
        };

        final profile = ProfileData.fromJson(json);
        expect(profile.rank, Rank.unranked);
      });

      test('parses different rank values correctly', () {
        final ranks = ['unranked', 'bronze', 'silver', 'gold', 'diamond', 'master', 'champion'];
        final expectedRanks = [
          Rank.unranked,
          Rank.bronze,
          Rank.silver,
          Rank.gold,
          Rank.diamond,
          Rank.master,
          Rank.champion,
        ];

        for (var i = 0; i < ranks.length; i++) {
          final json = {
            'uid': 'uid-$i',
            'username': 'User$i',
            'totalQuestionsAnswered': 0,
            'correctAnswers': 0,
            'rank': ranks[i],
            'ratingPoints': 0,
            'rankedGamesPlayed': 0,
            'rankedGamesWon': 0,
          };

          final profile = ProfileData.fromJson(json);
          expect(profile.rank, expectedRanks[i]);
        }
      });
    });

    group('toJson', () {
      test('returns JSON with all expected keys', () {
        final profile = ProfileData(
          uid: 'u1',
          username: 'Bob',
          totalQuestionsAnswered: 5,
          correctAnswers: 3,
          rank: Rank.silver,
          ratingPoints: 800,
          rankedGamesPlayed: 4,
          rankedGamesWon: 2,
        );

        final json = profile.toJson();

        expect(json['uid'], 'u1');
        expect(json['username'], 'Bob');
        expect(json['totalQuestionsAnswered'], 5);
        expect(json['correctAnswers'], 3);
        expect(json['rank'], Rank.silver);
        expect(json['ratingPoints'], 800);
        expect(json['rankedGamesPlayed'], 4);
        expect(json['rankedGamesWon'], 2);
      });

      test('includes uid in the JSON', () {
        final profile = ProfileData(uid: 'u1', username: 'Bob');
        expect(profile.toJson().containsKey('uid'), isTrue);
        expect(profile.toJson()['uid'], 'u1');
      });

      test('fromJson(toJson()) round-trip preserves all values', () {
        final original = ProfileData(
          uid: 'u1',
          username: 'Charlie',
          totalQuestionsAnswered: 10,
          correctAnswers: 7,
          rank: Rank.gold,
          ratingPoints: 2000,
          rankedGamesPlayed: 20,
          rankedGamesWon: 15,
        );

        final restored = ProfileData.fromJson(original.toJson());

        expect(restored.uid, original.uid);
        expect(restored.username, original.username);
        expect(restored.totalQuestionsAnswered, original.totalQuestionsAnswered);
        expect(restored.correctAnswers, original.correctAnswers);
        expect(restored.rank, original.rank);
        expect(restored.ratingPoints, original.ratingPoints);
        expect(restored.rankedGamesPlayed, original.rankedGamesPlayed);
        expect(restored.rankedGamesWon, original.rankedGamesWon);
      });
    });

    group('copyWith', () {
      test('creates new instance with updated values', () {
        final original = ProfileData(
          uid: 'u1',
          username: 'Alice',
          totalQuestionsAnswered: 10,
          correctAnswers: 5,
          rank: Rank.bronze,
          ratingPoints: 500,
          rankedGamesPlayed: 5,
          rankedGamesWon: 2,
        );

        final updated = original.copyWith(
          totalQuestionsAnswered: 20,
          correctAnswers: 15,
          rank: Rank.silver,
        );

        expect(updated.uid, 'u1');
        expect(updated.username, 'Alice');
        expect(updated.totalQuestionsAnswered, 20);
        expect(updated.correctAnswers, 15);
        expect(updated.rank, Rank.silver);
        expect(updated.ratingPoints, 500);
        expect(updated.rankedGamesPlayed, 5);
        expect(updated.rankedGamesWon, 2);
      });

      test('preserves all values when no parameters provided', () {
        final original = ProfileData(
          uid: 'u1',
          username: 'Bob',
          totalQuestionsAnswered: 10,
          correctAnswers: 5,
        );

        final copy = original.copyWith();

        expect(copy.uid, original.uid);
        expect(copy.username, original.username);
        expect(copy.totalQuestionsAnswered, original.totalQuestionsAnswered);
        expect(copy.correctAnswers, original.correctAnswers);
      });
    });
  });
}