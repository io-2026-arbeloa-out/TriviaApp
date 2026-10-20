import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/models/user_options.dart';

import 'package:triviaapp/repositories/firebase_options_repository.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';
import 'package:triviaapp/services/ui_options_service.dart';
import 'package:triviaapp/services/user_options_service.dart';

class MockFirebaseOptionsRepository extends Mock implements FirebaseOptionsRepository {}
class MockFirebaseProfileRepository extends Mock implements FirebaseProfileRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(UserOptions());
    registerFallbackValue(UIOptions());
  });

  test('UserOptionsService zapisuje opcje uzytkownika', () async {
    final repo = MockFirebaseOptionsRepository();
    final service = UserOptionsService(repo);

    when(() => repo.saveUserOptions(any())).thenAnswer((_) async => Future.value());

    await service.saveUserOptions(UserOptions());

    verify(() => repo.saveUserOptions(any())).called(1);
  });

  test('UserOptionsService pobiera opcje użytkownika', () async {
    final repo = MockFirebaseOptionsRepository();
    final service = UserOptionsService(repo);

    when(() => repo.getUserOptions()).thenAnswer((_) async => UserOptions(soundVolume: 30, musicVolume: 80));

    final result = await service.getUserOptions();

    expect(result.soundVolume, 30);
    expect(result.musicVolume, 80);
  });

  test('UIOptionsService zapisuje i ładuje ustawienia interfejsu', () async {
    final repo = MockFirebaseOptionsRepository();
    final profileRepo = MockFirebaseProfileRepository();

    final service = UIOptionsService(repo, profileRepo);

    final options = UIOptions().copyWith(mainColor: UIOptions().secondaryColor);

    when(() => repo.saveUIOptions(any()))
        .thenAnswer((_) async {});
    when(() => repo.getUIOptions(any()))
        .thenAnswer((_) async => options);

    when(() => profileRepo.getUIPreset())
        .thenAnswer((_) async => 'pr1');

    await service.saveUIOptions('pr1');
    final result = await service.getUIOptions();

    verify(() => repo.saveUIOptions('pr1')).called(1);
    verify(() => repo.getUIOptions('pr1')).called(1);

    expect(result, same(options));
  });

  test('UIOptionsService używa lokalnych opcji dla domyślnego presetu', () async {
    final repo = MockFirebaseOptionsRepository();
    final profileRepo = MockFirebaseProfileRepository();
    when(() => profileRepo.getUIPreset()).thenAnswer((_) async => 'default');

    final result = await UIOptionsService(repo, profileRepo).getUIOptions();

    expect(result, UIOptions());
    verifyNever(() => repo.getUIOptions(any()));
  });
}
