import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:triviaapp/models/ui_options.dart';

import 'package:triviaapp/repositories/options_repository.dart';
import 'package:triviaapp/repositories/profile_repository.dart';
import 'package:triviaapp/services/ui_options_service.dart';

class MockOptionsRepository extends Mock implements OptionsRepository {}
class MockProfileRepository extends Mock implements ProfileRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(UIOptions());
  });

  test('UIOptionsService zapisuje i ładuje ustawienia interfejsu', () async {
    final repo = MockOptionsRepository();
    final profileRepo = MockProfileRepository();

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
    final repo = MockOptionsRepository();
    final profileRepo = MockProfileRepository();
    when(() => profileRepo.getUIPreset()).thenAnswer((_) async => 'default');

    final result = await UIOptionsService(repo, profileRepo).getUIOptions();

    expect(result, UIOptions());
    verifyNever(() => repo.getUIOptions(any()));
  });
}
