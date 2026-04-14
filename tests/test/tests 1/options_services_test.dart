import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:TriviaApp/repositories/firebase_options_repository.dart';
import 'package:TriviaApp/services/game_options_service.dart';
import 'package:TriviaApp/services/ui_options_service.dart';
import 'package:TriviaApp/services/user_options_service.dart';

class MockFirebaseOptionsRepository extends Mock implements FirebaseOptionsRepository {}

void main() {
  test('UserOptionsService zapisuje opcje uzytkownika', () async {
    final repo = MockFirebaseOptionsRepository();
    final service = GameOptionsService(repo);

    when(() => repo.saveUserOptions(any())).thenAnswer((_) async => Future.value());

    await service.saveUserOptions({'timeLimit': 30});

    verify(() => repo.saveUserOptions(any())).called(1);
  });

  test('UserOptionsService pobiera opcje użytkownika', () async {
    final repo = MockFirebaseOptionsRepository();
    final service = UserOptionsService(repo);

    when(() => repo.getOptions()).thenAnswer((_) async => {'soundVolume': 80});

    final result = await service.getOptions();

    expect(result, isA<Map>());
  });

  test('UIOptionsService zapisuje i ładuje ustawienia interfejsu', () async {
    final repo = MockFirebaseOptionsRepository();
    final service = UIOptionsService(repo);

    when(() => repo.saveUIOptions(any())).thenAnswer((_) async => Future.value());
    when(() => repo.loadUIOptions()).thenAnswer((_) async => {'mainColor': '#000000'});

    await service.saveUIOptions({'mainColor': '#000000'});
    final result = await service.loadUIOptions();

    verify(() => repo.saveUIOptions(any())).called(1);
    expect(result, isA<Map>());
  });
}
