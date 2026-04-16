import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/models/user_options.dart';

import 'package:triviaapp/repositories/firebase_options_repository.dart';
import 'package:triviaapp/services/ui_options_service.dart';
import 'package:triviaapp/services/user_options_service.dart';

class MockFirebaseOptionsRepository extends Mock implements FirebaseOptionsRepository {}

void main() {
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

    expect(result, isA<Map>());
  });

  test('UIOptionsService zapisuje i ładuje ustawienia interfejsu', () async {
    final repo = MockFirebaseOptionsRepository();
    final service = UIOptionsService(repo);

    when(() => repo.saveUIOptions(any())).thenAnswer((_) async => Future.value());

    await service.saveUIOptions(UIOptions());
    final result = await service.getUIOptions();

    verify(() => repo.saveUIOptions(any())).called(1);
    expect(result, UIOptions());
  });
}
