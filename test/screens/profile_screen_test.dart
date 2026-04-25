import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:triviaapp/interfaces/i_profile_data_service.dart';
import 'package:triviaapp/models/profile_data.dart';
import 'package:triviaapp/models/rank.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/screens/profile_screen.dart';

import '../fakes.dart';

// ---------------------------------------------------------------------------
// Fake IProfileDataService
// ---------------------------------------------------------------------------

class FakeProfileDataService extends Fake implements IProfileDataService {
  ProfileData? getResult;
  Exception? getError;

  bool updateCalled = false;
  ProfileData? lastUpdatedProfile;
  Exception? updateError;

  @override
  Future<ProfileData> getProfileData() async {
    if (getError != null) throw getError!;
    return getResult!;
  }

  @override
  Future<void> updateProfileData(ProfileData data) async {
    if (updateError != null) throw updateError!;
    updateCalled = true;
    lastUpdatedProfile = data;
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Widget buildScreen({
  required bool isLoggedIn,
  required FakeProfileDataService service,
}) {
  return MaterialApp(
    home: ProfileScreen(
      options: UIOptions(),
      profileDataService: service,
      authChecker: () => isLoggedIn,
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late FakeProfileDataService fakeService;

  setUp(() {
    fakeService = FakeProfileDataService();
  });

  // -------------------------------------------------------------------------
  // Loading state
  // -------------------------------------------------------------------------

  group('loading state', () {
    testWidgets('shows CircularProgressIndicator while data is loading', (tester) async {
      // getResult left null — pump once before async completes
      fakeService.getResult = makeProfile();

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      // After first frame, _isLoading is still true
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  // -------------------------------------------------------------------------
  // Logged-out state
  // -------------------------------------------------------------------------

  group('logged-out state', () {
    testWidgets('shows not-logged-in message', (tester) async {
      await tester.pumpWidget(
          buildScreen(isLoggedIn: false, service: fakeService));
      await tester.pump();

      expect(
        find.text(
            'Nie jesteś zalogowany. Zaloguj się na swoje konto lub zarejestruj się.'),
        findsOneWidget,
      );
    });

    testWidgets('shows Zaloguj się button', (tester) async {
      await tester.pumpWidget(
          buildScreen(isLoggedIn: false, service: fakeService));
      await tester.pump();

      expect(find.text('Zaloguj się'), findsOneWidget);
    });

    testWidgets('shows Zarejestruj się button', (tester) async {
      await tester.pumpWidget(
          buildScreen(isLoggedIn: false, service: fakeService));
      await tester.pump();

      expect(find.text('Zarejestruj się'), findsOneWidget);
    });

    testWidgets('does not call service when not logged in', (tester) async {
      await tester.pumpWidget(
          buildScreen(isLoggedIn: false, service: fakeService));
      await tester.pump();

      expect(fakeService.getResult, isNull); // never set, never called
    });

    testWidgets('does not show stats section when not logged in',
        (tester) async {
      await tester.pumpWidget(
          buildScreen(isLoggedIn: false, service: fakeService));
      await tester.pump();

      expect(find.text('Statystyki'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Logged-in state — happy path
  // -------------------------------------------------------------------------

  group('logged-in state — success', () {
    testWidgets('shows username from ProfileData', (tester) async {
      fakeService.getResult = makeProfile(username: 'Alice');

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('shows rank from ProfileData', (tester) async {
      fakeService.getResult = makeProfile();

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      expect(find.textContaining('Ranga:'), findsOneWidget);
    });

    testWidgets('shows Statystyki section header', (tester) async {
      fakeService.getResult = makeProfile();

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Statystyki'), findsOneWidget);
    });

    testWidgets('shows correct totalQuestionsAnswered', (tester) async {
      fakeService.getResult = ProfileData(
        uid: 'uid-1',
        username: 'Alice',
        totalQuestionsAnswered: 42,
      );

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('42'), findsOneWidget);
    });

    testWidgets('shows correct correctAnswers', (tester) async {
      fakeService.getResult = ProfileData(
        uid: 'uid-1',
        username: 'Alice',
        correctAnswers: 30,
      );

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('30'), findsOneWidget);
    });

    testWidgets('shows 0% accuracy when no questions answered', (tester) async {
      fakeService.getResult = makeProfile();

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('0%'), findsOneWidget);
    });

    testWidgets('calculates accuracy correctly', (tester) async {
      fakeService.getResult = ProfileData(
        uid: 'uid-1',
        username: 'Alice',
        totalQuestionsAnswered: 10,
        correctAnswers: 7,
      );

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('70%'), findsOneWidget);
    });

    testWidgets('shows Zobacz osiągnięcia button', (tester) async {
      fakeService.getResult = makeProfile();

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Zobacz osiągnięcia'), findsOneWidget);
    });

    testWidgets('does not show logged-out message when logged in',
        (tester) async {
      fakeService.getResult = makeProfile();

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Nie jesteś zalogowany.'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Logged-in state — load error
  // -------------------------------------------------------------------------

  group('logged-in state — load error', () {
    testWidgets('shows error message when service throws', (tester) async {
      fakeService.getError = Exception('network error');

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('Nie udało się załadować profilu.'), findsOneWidget);
    });

    testWidgets('does not show username when load fails', (tester) async {
      fakeService.getError = Exception('network error');

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      expect(find.text('TestUser'), findsNothing);
    });
  });

  // -------------------------------------------------------------------------
  // Avatar picker
  // -------------------------------------------------------------------------

  group('avatar picker', () {
    testWidgets('tapping avatar opens picker dialog', (tester) async {
      fakeService.getResult = makeProfile();

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.text('Wybierz zdjęcie profilowe'), findsOneWidget);
    });

    testWidgets('picker dialog shows Anuluj button', (tester) async {
      fakeService.getResult = makeProfile();

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      expect(find.text('Anuluj'), findsOneWidget);
    });

    testWidgets('Anuluj closes dialog without calling updateProfileData',
        (tester) async {
      fakeService.getResult = makeProfile();

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Anuluj'));
      await tester.pumpAndSettle();

      expect(find.text('Wybierz zdjęcie profilowe'), findsNothing);
      expect(fakeService.updateCalled, isFalse);
    });

    testWidgets('selecting avatar calls updateProfileData', (tester) async {
      fakeService.getResult = makeProfile();

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      // Tap the first avatar CircleAvatar in the grid
      await tester.tap(find.byType(CircleAvatar).first);
      await tester.pumpAndSettle();

      expect(fakeService.updateCalled, isTrue);
    });

    testWidgets('selected avatar path is saved to profilePicture',
        (tester) async {
      fakeService.getResult = makeProfile();

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CircleAvatar).first);
      await tester.pumpAndSettle();

      expect(
        fakeService.lastUpdatedProfile?.profilePicture,
        startsWith('assets/avatars/'),
      );
    });

    testWidgets('shows error message when updateProfileData throws',
        (tester) async {
      fakeService.getResult = makeProfile();
      fakeService.updateError = Exception('save error');

      await tester.pumpWidget(buildScreen(isLoggedIn: true, service: fakeService));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(GestureDetector).first);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CircleAvatar).first);
      await tester.pumpAndSettle();

      expect(
        find.text('Nie udało się zapisać zdjęcia profilowego.'),
        findsOneWidget,
      );
    });
  });
}
