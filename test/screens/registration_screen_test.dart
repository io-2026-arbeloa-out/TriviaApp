import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/screens/registration_screen.dart';
import 'package:triviaapp/screens/main_menu_screen.dart';
import '../fakes.dart';

class _FakeFirebaseAuthException extends FirebaseAuthException {
  _FakeFirebaseAuthException(String code) : super(code: code);
}

void main() {
  late FakeRegisterAuthService fakeService;

  Widget buildSubject() => MaterialApp(
        home: RegistrationScreen(authService: fakeService),
      );

  setUp(() {
    fakeService = FakeRegisterAuthService();
  });

  group('RegistrationScreen — rendering', () {
    testWidgets('shows username, email and password fields', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(
          find.widgetWithText(TextField, 'Nazwa uzytkownika'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextField, 'Haslo'), findsOneWidget);
    });

    testWidgets('shows register button', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(
          find.widgetWithText(ElevatedButton, 'Zarejestruj'), findsOneWidget);
    });

    testWidgets('shows close button in AppBar', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byIcon(Icons.close), findsOneWidget);
    });
  });

  group('RegistrationScreen — validation', () {
    testWidgets('shows error snackbar when all fields are empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.widgetWithText(ElevatedButton, 'Zarejestruj'));
      await tester.pump();

      expect(find.text('Wypelnij wszystkie pola.'), findsOneWidget);
    });

    testWidgets('shows error snackbar when username is missing', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'a@b.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Haslo'), 'pass123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Zarejestruj'));
      await tester.pump();

      expect(find.text('Wypelnij wszystkie pola.'), findsOneWidget);
    });

    testWidgets('shows error snackbar when email is missing', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(
          find.widgetWithText(TextField, 'Nazwa uzytkownika'), 'Bob');
      await tester.enterText(
          find.widgetWithText(TextField, 'Haslo'), 'pass123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Zarejestruj'));
      await tester.pump();

      expect(find.text('Wypelnij wszystkie pola.'), findsOneWidget);
    });

    testWidgets('shows error snackbar when password is missing', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.enterText(
          find.widgetWithText(TextField, 'Nazwa uzytkownika'), 'Bob');
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'bob@test.com');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Zarejestruj'));
      await tester.pump();

      expect(find.text('Wypelnij wszystkie pola.'), findsOneWidget);
    });

    testWidgets('does not call service when any field is empty', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.tap(find.widgetWithText(ElevatedButton, 'Zarejestruj'));
      await tester.pump();

      expect(fakeService.registerResult, isNull);
    });
  });

  group('RegistrationScreen — registration flow', () {
    Future<void> fillAndSubmit(WidgetTester tester) async {
      await tester.enterText(
          find.widgetWithText(TextField, 'Nazwa uzytkownika'), 'Bob');
      await tester.enterText(
          find.widgetWithText(TextField, 'Email'), 'bob@test.com');
      await tester.enterText(
          find.widgetWithText(TextField, 'Haslo'), 'password123');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Zarejestruj'));
    }

    testWidgets('shows CircularProgressIndicator while awaiting service',
        (tester) async {
      final hangingService = _HangingRegisterService();
      await tester.pumpWidget(
          MaterialApp(home: RegistrationScreen(authService: hangingService)));

      await fillAndSubmit(tester);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(seconds: 10));
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
    });

    testWidgets('shows snackbar for "email-already-in-use" error',
        (tester) async {
      fakeService.registerError =
          _FakeFirebaseAuthException('email-already-in-use');

      await tester.pumpWidget(buildSubject());
      await fillAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Ten adres email jest juz zajety.'), findsOneWidget);
    });

    testWidgets('shows snackbar for "weak-password" error', (tester) async {
      fakeService.registerError =
          _FakeFirebaseAuthException('weak-password');

      await tester.pumpWidget(buildSubject());
      await fillAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(
          find.text('Haslo jest za slabe (min. 6 znakow).'), findsOneWidget);
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

      await tester.tap(find.byIcon(Icons.close));
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
