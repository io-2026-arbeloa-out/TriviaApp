import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/services/profile_data_service.dart';

import '../fakes.dart';

void main() {
  group('ProfileDataService', () {
    late FakeFirebaseProfileRepository fakeRepo;
    late ProfileDataService service;

    setUp(() {
      fakeRepo = FakeFirebaseProfileRepository();
      service = ProfileDataService(fakeRepo);
    });

    // -----------------------------------------------------------------------
    // getProfileData
    // -----------------------------------------------------------------------

    test('getProfileData returns data from repository', () async {
      fakeRepo.getResult = makeProfile();

      final result = await service.getProfileData();

      expect(result.uid, equals('uid-1'));
      expect(result.username, equals('TestUser'));
    });

    test('getProfileData returns data with all fields intact', () async {
      fakeRepo.getResult = makeProfile(uid: 'uid-99', username: 'Alice');

      final result = await service.getProfileData();

      expect(result.uid, equals('uid-99'));
      expect(result.username, equals('Alice'));
    });

    test('getProfileData propagates exception from repository', () async {
      fakeRepo.getError = Exception('network error');

      expect(() => service.getProfileData(), throwsException);
    });

    // -----------------------------------------------------------------------
    // updateProfileData
    // -----------------------------------------------------------------------

    test('updateProfileData calls repository', () async {
      final profile = makeProfile();

      await service.updateProfileData(profile);

      expect(fakeRepo.updateCalled, isTrue);
    });

    test('updateProfileData passes correct profile to repository', () async {
      final profile = makeProfile(uid: 'uid-42', username: 'Bob');

      await service.updateProfileData(profile);

      expect(fakeRepo.lastUpdatedProfile?.uid, equals('uid-42'));
      expect(fakeRepo.lastUpdatedProfile?.username, equals('Bob'));
    });

    test('updateProfileData passes profilePicture to repository', () async {
      final profile = makeProfile().copyWith(
        profilePicture: 'assets/avatars/avatar3.png',
      );

      await service.updateProfileData(profile);

      expect(
        fakeRepo.lastUpdatedProfile?.profilePicture,
        equals('assets/avatars/avatar3.png'),
      );
    });

    test('updateProfileData propagates exception from repository', () async {
      fakeRepo.updateError = Exception('write error');

      expect(
        () => service.updateProfileData(makeProfile()),
        throwsException,
      );
    });

    test('updateProfileData does not call repository when it throws', () async {
      fakeRepo.updateError = Exception('write error');

      try {
        await service.updateProfileData(makeProfile());
      } catch (_) {}

      expect(fakeRepo.updateCalled, isFalse);
    });
  });
}
