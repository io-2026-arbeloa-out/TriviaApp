import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/models/user_options.dart';
import 'package:triviaapp/repositories/firebase_options_repository.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late MockFirebaseAuth mockAuth;
  late FirebaseOptionsRepository repo;

  const tUid = 'uid1';
  final tUser = MockUser(uid: tUid, email: 'test@test.com');

  // Preset data matching struktura_bazy_danych.json
  final tPresetData = {
    'mainColor': '#E3F2FD',
    'secondaryColor': '#BBDEFB',
    'mainButtonColor': '#1976D2',
    'secondaryButtonColor': '#FFFFFF',
    'textColor': '#0D47A1',
  };

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    mockAuth = MockFirebaseAuth(mockUser: tUser, signedIn: true);
    repo = FirebaseOptionsRepository(
      firestore: fakeFirestore,
      auth: mockAuth,
    );
  });

  // ── uid getter ─────────────────────────────────────────────────────────────

  group('uid getter', () {
    test('returns uid when user is logged in', () {
      expect(repo.uid, tUid);
    });

    test('throws StateError when user is not logged in', () {
      final unauthRepo = FirebaseOptionsRepository(
        firestore: fakeFirestore,
        auth: MockFirebaseAuth(signedIn: false),
      );
      expect(() => unauthRepo.uid, throwsA(isA<StateError>()));
    });
  });

  // ── saveUserOptions ─────────────────────────────────────────────────────────

  group('saveUserOptions', () {
    test('writes soundVolume to user_options in Firestore', () async {
      const options = UserOptions(soundVolume: 75, musicVolume: 50);

      await repo.saveUserOptions(options);

      final doc = await fakeFirestore.collection('users').doc(tUid).get();
      final saved = doc.data()!['user_options'] as Map<String, dynamic>;
      expect(saved['soundVolume'], 75);
    });

    test('writes musicVolume to user_options in Firestore', () async {
      const options = UserOptions(soundVolume: 75, musicVolume: 50);

      await repo.saveUserOptions(options);

      final doc = await fakeFirestore.collection('users').doc(tUid).get();
      final saved = doc.data()!['user_options'] as Map<String, dynamic>;
      expect(saved['musicVolume'], 50);
    });

    test('merges with existing user data', () async {
      await fakeFirestore
          .collection('users')
          .doc(tUid)
          .set({'username': 'TestUser'});

      await repo.saveUserOptions(const UserOptions(soundVolume: 80, musicVolume: 60));

      final doc = await fakeFirestore.collection('users').doc(tUid).get();
      expect(doc.data()!['username'], 'TestUser');
    });
  });

  // ── getUserOptions ──────────────────────────────────────────────────────────

  group('getUserOptions', () {
    test('returns UserOptions with values from Firestore', () async {
      await fakeFirestore.collection('users').doc(tUid).set({
        'user_options': {'soundVolume': 60, 'musicVolume': 30},
      });

      final result = await repo.getUserOptions();

      expect(result.soundVolume, 60);
      expect(result.musicVolume, 30);
    });

    test('returns default UserOptions when document does not exist', () async {
      final result = await repo.getUserOptions();

      expect(result, isA<UserOptions>());
    });
  });

  // ── saveUIOptions ───────────────────────────────────────────────────────────

  group('saveUIOptions', () {
    test('writes preset string to ui_options field', () async {
      await repo.saveUIOptions('pr1');

      final doc = await fakeFirestore.collection('users').doc(tUid).get();
      expect(doc.data()!['ui_options'], 'pr1');
    });

    test('overwrites previous preset', () async {
      await repo.saveUIOptions('pr1');
      await repo.saveUIOptions('pr2');

      final doc = await fakeFirestore.collection('users').doc(tUid).get();
      expect(doc.data()!['ui_options'], 'pr2');
    });

    test('merges with existing user data', () async {
      await fakeFirestore
          .collection('users')
          .doc(tUid)
          .set({'username': 'TestUser'});

      await repo.saveUIOptions('pr1');

      final doc = await fakeFirestore.collection('users').doc(tUid).get();
      expect(doc.data()!['username'], 'TestUser');
    });
  });

  // ── getUIOptions ────────────────────────────────────────────────────────────

  group('getUIOptions', () {
    test('returns UIOptions when preset document exists', () async {
      await fakeFirestore
          .collection('ui_presets')
          .doc('pr1')
          .set(tPresetData);

      final result = await repo.getUIOptions('pr1');

      expect(result, isA<UIOptions>());
    });

    test('returns default UIOptions when preset document does not exist',
        () async {
      final result = await repo.getUIOptions('nonexistent');

      expect(result, isA<UIOptions>());
    });
  });

  // ── getUIPresets ────────────────────────────────────────────────────────────

  group('getUIPresets', () {
    test('returns map with all preset ids as keys', () async {
      await fakeFirestore
          .collection('ui_presets')
          .doc('pr1')
          .set(tPresetData);
      await fakeFirestore
          .collection('ui_presets')
          .doc('pr2')
          .set(tPresetData);

      final result = await repo.getUIPresets();

      expect(result.keys, containsAll(['pr1', 'pr2']));
    });

    test('returns correct number of presets', () async {
      await fakeFirestore
          .collection('ui_presets')
          .doc('pr1')
          .set(tPresetData);
      await fakeFirestore
          .collection('ui_presets')
          .doc('pr2')
          .set(tPresetData);

      final result = await repo.getUIPresets();

      expect(result.length, 2);
    });

    test('returns empty map when collection is empty', () async {
      final result = await repo.getUIPresets();

      expect(result, isEmpty);
    });

    test('skips malformed preset documents without throwing', () async {
      await fakeFirestore
          .collection('ui_presets')
          .doc('pr1')
          .set(tPresetData);
      // Intentionally malformed document — UIOptions.fromJson should fail gracefully
      await fakeFirestore
          .collection('ui_presets')
          .doc('bad')
          .set({'mainColor': 12345}); // wrong type

      // Should not throw — bad entry is silently skipped
      final result = await repo.getUIPresets();

      expect(result.containsKey('pr1'), isTrue);
    });
  });
}
