import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:TriviaApp/repositories/firebase_auth_repository.dart';
import 'package:TriviaApp/repositories/firebase_profile_repository.dart';
import 'package:TriviaApp/services/auth_login_service.dart';
import 'package:TriviaApp/services/auth_register_service.dart';

class MockFirebaseAuthRepository extends Mock implements FirebaseAuthRepository {}
class MockFirebaseProfileRepository extends Mock implements FirebaseProfileRepository {}

void main() {
  late MockFirebaseAuthRepository authRepository;
  late MockFirebaseProfileRepository profileRepository;
  late AuthLoginService loginService;
  late AuthRegisterService registerService;

  setUp(() {
    authRepository = MockFirebaseAuthRepository();
    profileRepository = MockFirebaseProfileRepository();
    loginService = AuthLoginService(authRepository);
    registerService = AuthRegisterService(authRepository, profileRepository);
  });

  test('AuthLoginService deleguje signInWithEmail do repozytorium', () async {
    when(() => authRepository.signInWithEmail(any(), any()))
        .thenAnswer((_) async => Future.value());

    await loginService.signInWithEmail('user@test.com', 'secret');

    verify(() => authRepository.signInWithEmail('user@test.com', 'secret')).called(1);
  });

  test('AuthLoginService deleguje signOut do repozytorium', () async {
    when(() => authRepository.signOut()).thenAnswer((_) async => Future.value());

    await loginService.signOut();

    verify(() => authRepository.signOut()).called(1);
  });

  test('AuthRegisterService rejestruje użytkownika i zapisuje profil', () async {
    final testProfile = ProfileData('User');

    when(() => authRepository.registerWithEmail(any(), any(), any()))
        .thenAnswer((_) async => testProfile);
    when(() => profileRepository.updateProfileData(any()))
        .thenAnswer((_) async => Future.value());

    final result = await registerService.register('user@test.com', 'secret', 'User');

    expect(result, same(testProfile));
    verify(() => authRepository.registerWithEmail('user@test.com', 'secret', 'User'))
        .called(1);
    verify(() => profileRepository.updateProfileData(testProfile)).called(1);
  });
}
