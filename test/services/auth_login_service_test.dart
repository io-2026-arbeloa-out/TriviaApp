import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/services/auth_login_service.dart';
import '../fakes.dart';

void main() {
  late FakeFirebaseAuthRepository fakeAuthRepo;
  late AuthLoginService service;

  setUp(() {
    fakeAuthRepo = FakeFirebaseAuthRepository();
    service = AuthLoginService(authRepository: fakeAuthRepo);
  });

  group('AuthLoginService.signInWithEmail', () {
    test('returns ProfileData from repository on success', () async {
      final expected = makeProfile(uid: 'u1', username: 'Alice');
      fakeAuthRepo.signInResult = expected;

      final result = await service.signInWithEmail('alice@test.com', 'pass123');

      expect(result.uid, expected.uid);
      expect(result.username, expected.username);
    });

    test('propagates exception thrown by repository', () async {
      fakeAuthRepo.signInError = Exception('user-not-found');

      expect(
        () => service.signInWithEmail('x@x.com', 'wrong'),
        throwsA(isA<Exception>()),
      );
    });

    test('propagates specific error message from repository', () async {
      fakeAuthRepo.signInError = Exception('wrong-password');

      expect(
        () => service.signInWithEmail('x@x.com', 'bad'),
        throwsA(predicate<Exception>(
          (e) => e.toString().contains('wrong-password'),
        )),
      );
    });
  });

  group('AuthLoginService.signOut', () {
    test('delegates signOut call to repository', () async {
      await service.signOut();
      expect(fakeAuthRepo.signOutCalled, isTrue);
    });
  });

  group('AuthLoginService.authStateChanges', () {
    test('returns stream from repository', () {
      final profile = makeProfile();
      fakeAuthRepo.authStream = Stream.value(profile);

      expect(service.authStateChanges(), emits(profile));
    });

    test('emits null when user is signed out', () {
      fakeAuthRepo.authStream = Stream.value(null);

      expect(service.authStateChanges(), emits(null));
    });

    test('emits multiple events in order', () {
      final profile = makeProfile();
      fakeAuthRepo.authStream = Stream.fromIterable([null, profile, null]);

      expect(
        service.authStateChanges(),
        emitsInOrder([null, profile, null]),
      );
    });
  });
}
