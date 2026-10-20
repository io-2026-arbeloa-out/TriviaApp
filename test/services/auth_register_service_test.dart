
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/services/auth_register_service.dart';
import '../fakes.dart';

void main() {
  late FakeAuthRepository fakeAuthRepo;
  late FakeProfileRepository fakeProfileRepo;
  late AuthRegisterService service;

  setUp(() {
    fakeAuthRepo = FakeAuthRepository();
    fakeProfileRepo = FakeProfileRepository();
    service = AuthRegisterService(
      authRepository: fakeAuthRepo,
      profileRepository: fakeProfileRepo,
    );
  });

  group('AuthRegisterService.register', () {
    test('returns ProfileData produced by auth repository', () async {
      final expected = makeProfile(uid: 'new-uid', username: 'Bob');
      fakeAuthRepo.registerResult = expected;

      final result = await service.register('bob@test.com', 'pass123', 'Bob');

      expect(result.uid, 'new-uid');
      expect(result.username, 'Bob');
    });

    test('calls updateProfileData on profile repository after auth', () async {
      final profile = makeProfile(uid: 'u2', username: 'Carol');
      fakeAuthRepo.registerResult = profile;

      await service.register('carol@test.com', 'secret', 'Carol');

      expect(fakeProfileRepo.updateCalled, isTrue);
    });

    test('saves exactly the ProfileData returned by auth repository', () async {
      final profile = makeProfile(uid: 'u3', username: 'Dave');
      fakeAuthRepo.registerResult = profile;

      await service.register('dave@test.com', 'pass', 'Dave');

      expect(fakeProfileRepo.lastUpdatedProfile?.uid, 'u3');
      expect(fakeProfileRepo.lastUpdatedProfile?.username, 'Dave');
    });

    test('propagates exception from auth repository without touching profile repo',
        () async {
      fakeAuthRepo.registerError = Exception('email-already-in-use');

      await expectLater(
        () => service.register('dup@test.com', 'pass', 'Dup'),
        throwsA(isA<Exception>()),
      );

      expect(fakeProfileRepo.updateCalled, isFalse);
    });

    test('reports incomplete registration when profile write fails', () async {
      fakeAuthRepo.registerResult = makeProfile();
      final error = Exception('firestore-write-failed');
      fakeProfileRepo.updateError = error;

      await expectLater(
        service.register('a@b.com', 'pass', 'User'),
        throwsA(isA<IncompleteRegistrationException>()
            .having((e) => e.cause, 'cause', same(error))),
      );
    });

    test('retries display name without creating another account', () async {
      fakeAuthRepo.registerResult = makeProfile();
      fakeAuthRepo.displayNameError = Exception('name-write-failed');

      await expectLater(service.register('a@b.com', 'pass', 'User'),
          throwsA(isA<IncompleteRegistrationException>()));
      expect(fakeProfileRepo.updateCalled, isFalse);
      fakeAuthRepo.displayNameError = null;

      final result = await service.register('a@b.com', 'pass', 'User');

      expect(fakeAuthRepo.registerCallCount, 1);
      expect(fakeAuthRepo.displayNameCallCount, 2);
      expect(fakeAuthRepo.updatedDisplayName, 'User');
      expect(fakeProfileRepo.lastUpdatedProfile?.uid, result.uid);
    });

    test('retries profile write without creating another account', () async {
      fakeAuthRepo.registerResult = makeProfile();
      fakeProfileRepo.updateError = Exception('profile-write-failed');

      await expectLater(service.register('a@b.com', 'pass', 'User'),
          throwsA(isA<IncompleteRegistrationException>()));
      fakeProfileRepo.updateError = null;

      await service.register('a@b.com', 'pass', 'New name');

      expect(fakeAuthRepo.registerCallCount, 1);
      expect(fakeAuthRepo.updatedDisplayName, 'New name');
      expect(fakeProfileRepo.lastUpdatedProfile?.username, 'New name');
    });

    test('does not attach another email to pending registration', () async {
      fakeAuthRepo.registerResult = makeProfile();
      fakeProfileRepo.updateError = Exception('profile-write-failed');

      await expectLater(service.register('a@b.com', 'pass', 'User'),
          throwsA(isA<IncompleteRegistrationException>()));
      fakeProfileRepo.updateError = null;
      await expectLater(service.register('other@b.com', 'pass', 'Other'),
          throwsA(isA<IncompleteRegistrationException>()));

      expect(fakeAuthRepo.registerCallCount, 1);
      expect(fakeProfileRepo.updateCalled, isFalse);
      await service.register('a@b.com', 'pass', 'User');
      expect(fakeProfileRepo.updateCalled, isTrue);
    });

    test('does not call profile repository when auth throws', () async {
      fakeAuthRepo.registerError = Exception('weak-password');

      try {
        await service.register('a@b.com', '1', 'X');
      } catch (_) {}

      expect(fakeProfileRepo.updateCalled, isFalse);
    });
  });

  group('AuthRegisterService.authStateChanges', () {
    test('delegates stream to auth repository', () {
      final profile = makeProfile();
      fakeAuthRepo.authStream = Stream.value(profile);

      expect(service.authStateChanges(), emits(profile));
    });

    test('emits null when no user is authenticated', () {
      fakeAuthRepo.authStream = Stream.value(null);

      expect(service.authStateChanges(), emits(null));
    });
  });
}
