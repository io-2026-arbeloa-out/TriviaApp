import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:triviaapp/app_dependencies.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/models/user_options.dart';
import 'package:triviaapp/screens/login_screen.dart';
import 'package:triviaapp/screens/profile_screen.dart';
import 'package:triviaapp/screens/quiz_list_screen.dart';
import 'package:triviaapp/screens/registration_screen.dart';
import 'package:triviaapp/screens/user_options_screen.dart';

void main() {
  final routes = <String, Type>{
    AppRoute.loginScreen: LoginScreen,
    AppRoute.registrationScreen: RegistrationScreen,
    AppRoute.profileScreen: ProfileScreen,
    AppRoute.quizListScreen: QuizListScreen,
    AppRoute.userOptionsScreen: UserOptionsScreen,
  };
  for (final route in routes.entries) {
    testWidgets(
      'route ${route.key} uses its supplied dependency graph without a default Firebase app',
      (tester) async {
        final db = FakeFirebaseFirestore();
        final auth = MockFirebaseAuth(
          mockUser: MockUser(uid: 'injected'),
          signedIn: true,
        );
        final deps = AppDependencies(auth: auth, firestore: db);
        await db
            .collection('users')
            .doc('injected')
            .set(
              const ProfileData(uid: 'injected', username: 'Injected').toJson(),
            );
        await tester.pumpWidget(
          MaterialApp(
            navigatorKey: AppRoute.instance.navigatorKey,
            initialRoute: route.key,
            onGenerateRoute: (settings) => AppRoute.instance.onGenerateRoute(
              RouteSettings(
                name: settings.name,
                arguments: settings.arguments ?? const UIOptions(),
              ),
              dependencies: deps,
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.byType(route.value), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  test(
    'registration and appearance use the supplied Auth and Firestore throughout the graph',
    () async {
      final db = FakeFirebaseFirestore();
      final auth = MockFirebaseAuth();
      final deps = AppDependencies(auth: auth, firestore: db);

      final profile = await deps.createRegistrationService().register(
        'test@example.com',
        'password123',
        'User',
      );
      expect(profile.uid, auth.currentUser!.uid);
      expect(auth.currentUser!.displayName, 'User');
      expect(
        (await db.collection('users').doc(profile.uid).get())
            .data()!['username'],
        'User',
      );
      expect(deps.authRepository.isSignedIn, true);

      final preset = const UIOptions().copyWith(
        mainColor: const UIOptions().secondaryColor,
      );
      await db.collection('ui_presets').doc('custom').set(preset.toJson());
      await deps.uiOptionsService.saveUIOptions('custom');
      expect(await deps.uiOptionsService.getUIOptions(), preset);
      await deps.optionsRepository.saveUserOptions(
        const UserOptions(soundVolume: 10, musicVolume: 20, sfxVolume: 30),
      );
      expect(
        await deps.optionsRepository.getUserOptions(),
        const UserOptions(soundVolume: 10, musicVolume: 20, sfxVolume: 30),
      );
      expect(
        (await deps.profileRepository.getProfileData()).uiPreset,
        'custom',
      );

      await db.collection('quizzes').doc('quiz').set({
        'category': 'science',
        'title': 'Science',
      });
      expect(
        (await deps.quizRepository.getQuizList()).single.category,
        'science',
      );
      await deps.authRepository.signOut();
      expect(auth.currentUser, isNull);
    },
  );

  test('registration state is scoped to a single form instance', () async {
    final deps = AppDependencies(
      auth: MockFirebaseAuth(),
      firestore: FakeFirebaseFirestore(),
    );
    expect(
      identical(
        deps.createRegistrationService(),
        deps.createRegistrationService(),
      ),
      false,
    );
  });
}
