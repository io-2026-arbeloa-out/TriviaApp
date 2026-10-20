import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/screens/login_screen.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/screens/main_menu_screen.dart';
import 'package:triviaapp/models/profile_data.dart';
import '../fakes.dart';

// FirebaseAuthException cannot be constructed directly in tests without
// Firebase initialization, so we use a plain exception for error-path tests
// and only test FirebaseAuthException handling via a subclass workaround.
class _FakeFirebaseAuthException extends FirebaseAuthException {
  _FakeFirebaseAuthException(String code) : super(code: code);
}

Future<void> tapLogin(WidgetTester tester) async {
  await tester.pumpAndSettle();
  final button = find.widgetWithText(ElevatedButton, 'Zaloguj');
  await tester.ensureVisible(button);
  await tester.pumpAndSettle();
  await tester.tap(button);
}

void main() {
  late FakeAuthRepository fakeService;

  Widget buildSubject() => MaterialApp(
        navigatorKey: AppRoute.instance.navigatorKey,
        initialRoute: '/login-test',
        routes: {
          '/login-test': (_) => LoginScreen(authRepository: fakeService),
          AppRoute.mainMenuScreen: (_) => MainMenuScreen(authChecker: () => true),
        },
      );

  setUp(() {
    fakeService = FakeAuthRepository();
  });

  group('LoginScreen — rendering', () {
    testWidgets('shows email and password fields', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Haslo'), findsOneWidget);
    });

    testWidgets('shows login button', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.widgetWithText(ElevatedButton, 'Zaloguj'), findsOneWidget);
    });

    testWidgets('shows register navigation button', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(TextButton), findsOneWidget);
    });
  });

  group('LoginScreen — validation', () {
    testWidgets('shows error banner when email is empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(
          find.widgetWithText(TextField, 'Haslo'), 'pass123');
      await tapLogin(tester);
      await tester.pump();

      expect(find.text('Wypelnij wszystkie pola.'), findsOneWidget);
      expect(fakeService.signInCallCount, 0);
    });

    testWidgets('shows error banner when password is empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'a@b.com');
      await tapLogin(tester);
      await tester.pump();

      expect(find.text('Wypelnij wszystkie pola.'), findsOneWidget);
      expect(fakeService.signInCallCount, 0);
    });

    testWidgets('does not call service when fields are empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tapLogin(tester);
      await tester.pump();

      // service was never called — no interaction happened
      expect(fakeService.signInCallCount, 0);
    });
  });

  group('LoginScreen — login flow', () {
    testWidgets('keeps the form usable on a small screen with the keyboard open',
        (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetViewInsets);

      await tester.pumpWidget(buildSubject());
      await tapLogin(tester);
      await tester.pumpAndSettle();

      expect(find.text('Wypelnij wszystkie pola.'), findsOneWidget);
      expect(fakeService.signInCallCount, 0);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows CircularProgressIndicator while awaiting service',
        (tester) async {
      // Never-completing future keeps the loading state visible.
      final hangingService = _HangingLoginService();
      await tester.pumpWidget(
          MaterialApp(home: LoginScreen(authRepository: hangingService)));

      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'a@b.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Haslo'), 'pass123');
      await tapLogin(tester);
      await tester.pump(); // trigger setState

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    });

    testWidgets('navigates to MainMenuScreen on successful login',
        (tester) async {
      fakeService.signInResult = makeProfile();

      await tester.pumpWidget(buildSubject());
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'a@b.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Haslo'), 'pass123');
      await tapLogin(tester);
      await tester.pumpAndSettle();

      expect(find.byType(MainMenuScreen), findsOneWidget);
    });

    testWidgets('shows error banner message on FirebaseAuthException',
        (tester) async {
      fakeService.signInError =
          _FakeFirebaseAuthException('wrong-password');

      await tester.pumpWidget(buildSubject());
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'a@b.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Haslo'), 'badpass');
      await tapLogin(tester);
      await tester.pumpAndSettle();

      expect(find.text('Nieprawidlowe haslo.'), findsOneWidget);
    });

    testWidgets('shows generic error message on unknown exception',
        (tester) async {
      fakeService.signInError = Exception('network-failure');

      await tester.pumpWidget(buildSubject());
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'a@b.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Haslo'), 'pass');
      await tapLogin(tester);
      await tester.pumpAndSettle();

      expect(find.text('Wystapil nieoczekiwany blad.'), findsOneWidget);
    });

    testWidgets('does not navigate on login failure', (tester) async {
      fakeService.signInError = Exception('error');

      await tester.pumpWidget(buildSubject());
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'a@b.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Haslo'), 'bad');
      await tapLogin(tester);
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}

// Fake service whose signInWithEmail never completes — used to assert
// loading indicator visibility.
class _HangingLoginService extends FakeAuthRepository {
  @override
  Future<ProfileData> signInWithEmail(String email, String password) =>
      Completer<ProfileData>().future;
}
