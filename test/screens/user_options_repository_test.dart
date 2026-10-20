import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/models/user_options.dart';
import 'package:triviaapp/repositories/options_repository.dart';
import 'package:triviaapp/screens/user_options_screen.dart';
import 'package:triviaapp/services/ui_options_service.dart';
import '../fakes.dart';

class _Options extends Fake implements OptionsRepository {
  UserOptions? saved;
  String? preset;
  bool failSave = false;
  @override
  Future<UserOptions> getUserOptions() async =>
      const UserOptions(soundVolume: 10, musicVolume: 20, sfxVolume: 30);
  @override
  Future<Map<String, UIOptions>> getUIPresets() async => {
    'custom': const UIOptions(),
  };
  @override
  Future<void> saveUserOptions(UserOptions value) async {
    if (failSave) throw Exception('Unavailable');
    saved = value;
  }

  @override
  Future<void> saveUIOptions(String value) async {
    preset = value;
  }
}

void main() {
  for (final fail in [false, true]) {
    testWidgets(
      'settings save through the supplied repository (failure=$fail)',
      (tester) async {
        tester.view.physicalSize = const Size(430, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final repo = _Options()..failSave = fail;
        final profile = FakeProfileRepository()..uiPreset = 'custom';
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: AppRoute.instance.navigatorKey,
            initialRoute: '/options-test',
            routes: {
              '/options-test': (_) => UserOptionsScreen(
                optionsRepository: repo,
                uiOptionsService: UIOptionsService(repo, profile),
              ),
              AppRoute.mainMenuScreen: (_) =>
                  const Scaffold(body: Text('Saved')),
            },
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.widget<Slider>(find.byType(Slider).at(1)).value, 20);
        await tester.drag(find.byType(Slider).at(1), const Offset(70, 0));
        await tester.pump();
        final music = tester
            .widget<Slider>(find.byType(Slider).at(1))
            .value
            .floor();
        expect(music, greaterThan(20));
        final button = find.widgetWithText(ElevatedButton, 'Zapisz');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();
        if (fail) {
          expect(find.text('Nie udało się zapisać ustawień.'), findsOneWidget);
          expect(find.text('Saved'), findsNothing);
        } else {
          expect(
            repo.saved,
            UserOptions(soundVolume: 10, musicVolume: music, sfxVolume: 30),
          );
          expect(repo.preset, 'custom');
          expect(find.text('Saved'), findsOneWidget);
        }
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
