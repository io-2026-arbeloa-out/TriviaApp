
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/services/auth_register_service.dart';
import 'fakes.dart';

void main() {
  late FakeFirebaseAuthRepository fakeAuthRepo;
  late FakeFirebaseProfileRepository fakeProfileRepo;
  late AuthRegisterService service;

  setUp(() {
    fakeAuthRepo = FakeFirebaseAuthRepository();
    fakeProfileRepo = FakeFirebaseProfileRepository();
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

    test('propagates exception from profile repository', () async {
      fakeAuthRepo.registerResult = makeProfile();
      fakeProfileRepo.updateError = Exception('firestore-write-failed');

      expect(
        () => service.register('a@b.com', 'pass', 'User'),
        throwsA(predicate<Exception>(
          (e) => e.toString().contains('firestore-write-failed'),
        )),
      );
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
