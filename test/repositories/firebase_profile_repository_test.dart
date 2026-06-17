import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/models/user_options.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late FirebaseProfileRepository repo;

  // uid pobieramy z mockAuth, nie hardkodujemy
  late String uid;

  final tUser = MockUser(uid: 'uid1', email: 'test@test.com');

  final tDocData = {
    'username': 'TestUser',
    'totalQuestionsAnswered': 10,
    'correctAnswers': 7,
    'rank': 'unranked',
    'ratingPoints': 100,
    'rankedGamesPlayed': 5,
    'rankedGamesWon': 2,
    'user_options': {'soundVolume': 80, 'musicVolume': 60},
    'ui_options': 'default',
    'profilePicture': 'assets/avatars/avatar2.png',
  };

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(mockUser: tUser, signedIn: true);
    repo = FirebaseProfileRepository(
      firestore: fakeFirestore,
      auth: mockAuth,
    );
    // ← ZMIANA: uid zawsze pochodzi z tego samego mockAuth co repo
    uid = mockAuth.currentUser!.uid;
  });

  // ── uid getter ─────────────────────────────────────────────────────────────

  group('uid getter', () {
    test('returns uid when user is logged in', () {
      expect(repo.uid, uid);
    });

    test('throws Exception when no user is logged in', () {
      final unauthRepo = FirebaseProfileRepository(
        firestore: fakeFirestore,
        auth: MockFirebaseAuth(signedIn: false),
      );
      expect(() => unauthRepo.uid, throwsException);
    });
  });

  // ── getProfileData ──────────────────────────────────────────────────────────

  group('getProfileData', () {
    test('returns ProfileData with correct uid', () async {
      await fakeFirestore.collection('users').doc(uid).set(tDocData);

      final result = await repo.getProfileData();

      expect(result.uid, uid);
    });

    test('maps all scalar fields correctly', () async {
      await fakeFirestore.collection('users').doc(uid).set(tDocData);

      final result = await repo.getProfileData();

      expect(result.username, 'TestUser');
      expect(result.totalQuestionsAnswered, 10);
      expect(result.correctAnswers, 7);
      expect(result.ratingPoints, 100);
      expect(result.rankedGamesPlayed, 5);
      expect(result.rankedGamesWon, 2);
    });

    test('maps profilePicture correctly', () async {
      await fakeFirestore.collection('users').doc(uid).set(tDocData);

      final result = await repo.getProfileData();

      expect(result.profilePicture, 'assets/avatars/avatar2.png');
    });

    test('defaults profilePicture to empty string when field is missing',
            () async {
          final dataWithoutPicture = Map<String, dynamic>.from(tDocData)
            ..remove('profilePicture');
          await fakeFirestore.collection('users').doc(uid).set(dataWithoutPicture);

          final result = await repo.getProfileData();

          expect(result.profilePicture, '');
        });

    test('maps user_options correctly', () async {
      await fakeFirestore.collection('users').doc(uid).set(tDocData);

      final result = await repo.getProfileData();

      expect(result.userOptions.soundVolume, 80);
      expect(result.userOptions.musicVolume, 60);
    });

    test('maps ui_options preset string correctly', () async {
      await fakeFirestore.collection('users').doc(uid).set(tDocData);

      final result = await repo.getProfileData();

      expect(result.uiPreset, 'default');
    });

    test('throws Exception when document does not exist', () async {
      expect(() => repo.getProfileData(), throwsException);
    });

    test('uses default UserOptions when user_options field is missing',
            () async {
          final dataWithoutOptions = Map<String, dynamic>.from(tDocData)
            ..remove('user_options');
          await fakeFirestore.collection('users').doc(uid).set(dataWithoutOptions);

          final result = await repo.getProfileData();

          expect(result.userOptions, isA<UserOptions>());
        });
  });

  // ── updateProfileData ───────────────────────────────────────────────────────

  group('updateProfileData', () {
    // ← ZMIANA: ProfileData budowany z uid pobranym z mockAuth
    late ProfileData tProfile;

    setUp(() {
      tProfile = ProfileData(
        uid: uid,
        username: 'TestUser',
        totalQuestionsAnswered: 5,
        correctAnswers: 3,
        ratingPoints: 50,
        rankedGamesPlayed: 2,
        rankedGamesWon: 1,
        userOptions: const UserOptions(soundVolume: 70, musicVolume: 40),
        uiPreset: 'pr1',
        profilePicture: 'assets/avatars/avatar3.png',
      );
    });

    test('creates document with correct username', () async {
      await repo.updateProfileData(tProfile);

      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.data()!['username'], 'TestUser');
    });

    test('writes ratingPoints correctly', () async {
      await repo.updateProfileData(tProfile);

      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.data()!['ratingPoints'], 50);
    });

    test('writes ui_options preset string correctly', () async {
      await repo.updateProfileData(tProfile);

      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.data()!['ui_options'], 'pr1');
    });

    test('writes profilePicture correctly', () async {
      await repo.updateProfileData(tProfile);

      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.data()!['profilePicture'], 'assets/avatars/avatar3.png');
    });

    test('does not write uid as a field in the document', () async {
      await repo.updateProfileData(tProfile);

      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.data()!.containsKey('uid'), isFalse);
    });

    test('merges with existing data (does not overwrite unrelated fields)',
            () async {
          await fakeFirestore
              .collection('users')
              .doc(uid)
              .set({'someOtherField': 'keepMe'});

          await repo.updateProfileData(tProfile);

          final doc = await fakeFirestore.collection('users').doc(uid).get();
          expect(doc.data()!['someOtherField'], 'keepMe');
        });

    test('overwrites existing profilePicture with new value', () async {
      await fakeFirestore
          .collection('users')
          .doc(uid)
          .set({'profilePicture': 'assets/avatars/avatar1.png'});

      await repo.updateProfileData(tProfile);

      final doc = await fakeFirestore.collection('users').doc(uid).get();
      expect(doc.data()!['profilePicture'], 'assets/avatars/avatar3.png');
    });
  });

  // ── getUIPreset ─────────────────────────────────────────────────────────────

  group('getUIPreset', () {
    test('returns preset string from document', () async {
      await fakeFirestore
          .collection('users')
          .doc(uid)
          .set({'ui_options': 'pr2'});

      final result = await repo.getUIPreset();

      expect(result, 'pr2');
    });

    test('returns default when document does not exist', () async {
      final result = await repo.getUIPreset();

      expect(result, 'default');
    });

    test('returns default when ui_options field is missing', () async {
      await fakeFirestore
          .collection('users')
          .doc(uid)
          .set({'username': 'TestUser'});

      final result = await repo.getUIPreset();

      expect(result, 'default');
    });
  });
}