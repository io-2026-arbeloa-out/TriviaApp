import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/screens/registration_screen.dart';
import 'package:triviaapp/screens/main_menu_screen.dart';
import '../fakes.dart';

class _FakeFirebaseAuthException extends FirebaseAuthException {
  _FakeFirebaseAuthException(String code) : super(code: code);
}

Future<void> tapRegister(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final button = find.widgetWithText(ElevatedButton, 'Zarejestruj');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
}

void main() {
  late FakeRegisterAuthService fakeService;

  Widget buildSubject() => MaterialApp(
        navigatorKey: AppRoute.instance.navigatorKey,
        initialRoute: '/registration-test',
        routes: {
          '/registration-test': (_) => RegistrationScreen(authService: fakeService),
          AppRoute.mainMenuScreen: (_) => MainMenuScreen(authChecker: () => true),
        },
      );

  setUp(() {
    fakeService = FakeRegisterAuthService();
  });

  group('RegistrationScreen — rendering', () {
    testWidgets('shows username, email and password fields', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(
          find.widgetWithText(TextField, 'Nazwa użytkownika'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Hasło'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Potwierdź hasło'), findsOneWidget);
    });

    testWidgets('shows register button', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(
          find.widgetWithText(ElevatedButton, 'Zarejestruj'), findsOneWidget);
    });

    testWidgets('shows close button in AppBar', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });

  group('RegistrationScreen — validation', () {
    testWidgets('shows error banner when all fields are empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tapRegister(tester);
      await tester.pump();

      expect(find.text('Wypelnij wszystkie pola.'), findsOneWidget);
    });

    testWidgets('shows error banner when username is missing', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'a@b.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Hasło'), 'pass123');
      await tester.enterText(
          find.widgetWithText(TextField, 'Potwierdź hasło'), 'pass123');
      await tapRegister(tester);
      await tester.pump();

      expect(find.text('Wypelnij wszystkie pola.'), findsOneWidget);
      expect(fakeService.registerCallCount, 0);
    });

    testWidgets('shows error banner when email is missing', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(
          find.widgetWithText(TextField, 'Nazwa użytkownika'), 'Bob');
      await tester.enterText(
          find.widgetWithText(TextField, 'Hasło'), 'pass123');
      await tester.enterText(
          find.widgetWithText(TextField, 'Potwierdź hasło'), 'pass123');
      await tapRegister(tester);
      await tester.pump();

      expect(find.text('Wypelnij wszystkie pola.'), findsOneWidget);
      expect(fakeService.registerCallCount, 0);
    });

    testWidgets('shows error banner when password is missing', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(
          find.widgetWithText(TextField, 'Nazwa użytkownika'), 'Bob');
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'bob@test.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Potwierdź hasło'), 'pass123');
      await tapRegister(tester);
      await tester.pump();

      expect(find.text('Wypelnij wszystkie pola.'), findsOneWidget);
      expect(fakeService.registerCallCount, 0);
    });

    testWidgets('does not register without password confirmation', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(
          find.widgetWithText(TextField, 'Nazwa użytkownika'), 'Bob');
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'bob@test.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Hasło'), 'pass123');
      await tapRegister(tester);
      await tester.pumpAndSettle();

      expect(find.text('Wypelnij wszystkie pola.'), findsOneWidget);
      expect(fakeService.registerCallCount, 0);
    });

    testWidgets('does not call service when any field is empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tapRegister(tester);
      await tester.pump();

      expect(fakeService.registerCallCount, 0);
    });
  });

  group('RegistrationScreen — registration flow', () {
    Future<void> fillAndSubmit(WidgetTester tester) async {
      await tester.enterText(
          find.widgetWithText(TextField, 'Nazwa użytkownika'), 'Bob');
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'bob@test.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Hasło'), 'password123');
      await tester.enterText(
          find.widgetWithText(TextField, 'Potwierdź hasło'), 'password123');
      await tapRegister(tester);
    }

    testWidgets('keeps the form usable on a small screen with the keyboard open',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);
      fakeService.registerError = _FakeFirebaseAuthException('weak-password');

      await tester.pumpWidget(buildSubject());
      await fillAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Hasło jest za słabe (min. 6 znaków).'), findsOneWidget);
      expect(fakeService.registerCallCount, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows CircularProgressIndicator while awaiting service',
        (tester) async {
      final hangingService = _HangingRegisterService();
      await tester.pumpWidget(
          MaterialApp(home: RegistrationScreen(authService: hangingService)));

      await fillAndSubmit(tester);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('navigates to MainMenuScreen and clears stack on success',
        (tester) async {
      fakeService.registerResult = makeProfile(username: 'Bob');

      await tester.pumpWidget(buildSubject());
      await fillAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.byType(MainMenuScreen), findsOneWidget);
      // RegistrationScreen must no longer be in the stack
      expect(find.byType(RegistrationScreen), findsNothing);
      expect(AppRoute.instance.navigatorKey.currentState!.canPop(), isFalse);
    });

    testWidgets('shows error banner for "email-already-in-use" error',
        (tester) async {
      fakeService.registerError =
          _FakeFirebaseAuthException('email-already-in-use');

      await tester.pumpWidget(buildSubject());
      await fillAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Ten adres email jest już zajęty.'), findsOneWidget);
    });

    testWidgets('shows error banner for "weak-password" error', (tester) async {
      fakeService.registerError =
          _FakeFirebaseAuthException('weak-password');

      await tester.pumpWidget(buildSubject());
      await fillAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(
          find.text('Hasło jest za słabe (min. 6 znaków).'), findsOneWidget);
    });

    testWidgets('shows generic error message on unknown exception',
        (tester) async {
      fakeService.registerError = Exception('unexpected');

      await tester.pumpWidget(buildSubject());
      await fillAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Wystapil nieoczekiwany blad.'), findsOneWidget);
    });

    testWidgets('stays on RegistrationScreen after failure', (tester) async {
      fakeService.registerError = Exception('error');

      await tester.pumpWidget(buildSubject());
      await fillAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.byType(RegistrationScreen), findsOneWidget);
    });
  });

  group('RegistrationScreen — close button', () {
    testWidgets('pops screen when close button is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: AppRoute.instance.navigatorKey,
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => Navigator.of(ctx).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        RegistrationScreen(authService: fakeService),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.byType(RegistrationScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      expect(find.byType(RegistrationScreen), findsNothing);
    });
  });
}

class _HangingRegisterService extends FakeRegisterAuthService {
  @override
  Future<ProfileData> register(String email, String password, String username) =>
      Completer<ProfileData>().future;
}
