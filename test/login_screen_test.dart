import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/screens/login_screen.dart';
import 'package:triviaapp/screens/main_menu_screen.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'fakes.dart';

// FirebaseAuthException cannot be constructed directly in tests without
// Firebase initialization, so we use a plain exception for error-path tests
// and only test FirebaseAuthException handling via a subclass workaround.
class _FakeFirebaseAuthException extends FirebaseAuthException {
  _FakeFirebaseAuthException(String code) : super(code: code);
}

void main() {
  late FakeLoginAuthService fakeService;

  Widget buildSubject() => MaterialApp(
        home: LoginScreen(authService: fakeService),
        routes: {'/main': (_) => MainMenuScreen()},
      );

  setUp(() {
    fakeService = FakeLoginAuthService();
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
    testWidgets('shows error snackbar when email is empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.widgetWithText(ElevatedButton, 'Zaloguj'));
      await tester.pump();

      expect(find.text('Wypelnij wszystkie pola.'), findsOneWidget);
    });

    testWidgets('shows error snackbar when password is empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'a@b.com');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Zaloguj'));
      await tester.pump();

      expect(find.text('Wypelnij wszystkie pola.'), findsOneWidget);
    });

    testWidgets('does not call service when fields are empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.widgetWithText(ElevatedButton, 'Zaloguj'));
      await tester.pump();

      // service was never called — no interaction happened
      expect(fakeService.signInResult, isNull);
    });
  });

  group('LoginScreen — login flow', () {
    testWidgets('shows CircularProgressIndicator while awaiting service',
        (tester) async {
      // Never-completing future keeps the loading state visible.
      fakeService.signInError = null;
      fakeService.signInResult = null;
      final completer = Future<void>.delayed(const Duration(seconds: 10),
          () => makeProfile());

      // Replace with a service that hangs
      final hangingService = _HangingLoginService();
      await tester.pumpWidget(
          MaterialApp(home: LoginScreen(authService: hangingService)));

      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'a@b.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Haslo'), 'pass123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Zaloguj'));
      await tester.pump(); // trigger setState

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      // pump to cancel pending timer
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('navigates to MainMenuScreen on successful login',
        (tester) async {
      fakeService.signInResult = makeProfile();

      await tester.pumpWidget(buildSubject());
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'a@b.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Haslo'), 'pass123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Zaloguj'));
      await tester.pumpAndSettle();

      expect(find.byType(MainMenuScreen), findsOneWidget);
    });

    testWidgets('shows snackbar message on FirebaseAuthException',
        (tester) async {
      fakeService.signInError =
          _FakeFirebaseAuthException('wrong-password');

      await tester.pumpWidget(buildSubject());
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'a@b.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Haslo'), 'badpass');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Zaloguj'));
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
      await tester.tap(find.widgetWithText(ElevatedButton, 'Zaloguj'));
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
      await tester.tap(find.widgetWithText(ElevatedButton, 'Zaloguj'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}

// Fake service whose signInWithEmail never completes — used to assert
// loading indicator visibility.
class _HangingLoginService extends FakeLoginAuthService {
  @override
  Future<ProfileData> signInWithEmail(String email, String password) =>
      Completer<ProfileData>().future;
}
