import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:triviaapp/screens/login_screen.dart';
import 'package:triviaapp/screens/profile_screen.dart';
import 'package:triviaapp/screens/quiz_list_screen.dart';
import 'package:triviaapp/screens/registration_screen.dart';
import 'package:triviaapp/screens/score_table_screen.dart';
import 'package:triviaapp/services/achievements_service.dart';
import 'package:triviaapp/services/auth_login_service.dart';
import 'package:triviaapp/services/profile_data_service.dart';
import 'package:triviaapp/services/quiz_list_service.dart';
import 'package:triviaapp/services/auth_register_service.dart';
import 'package:triviaapp/services/score_table_service.dart';

class MockLoginAuthService extends Mock implements AuthLoginService {}
class MockRegisterAuthService extends Mock implements AuthRegisterService {}
class MockQuizListService extends Mock implements QuizListService {}
class MockProfileDataService extends Mock implements ProfileDataService {}
class MockAchievementService extends Mock implements AchievementService {}
class MockScoreTableService extends Mock implements ScoreTableService {}

void main() {
  testWidgets('LoginScreen loguje użytkownika po kliknięciu', (tester) async {
    final authService = MockLoginAuthService();
    when(() => authService.signInWithEmail(any(), any())).thenAnswer((_) async => Future.value());

    await tester.pumpWidget(MaterialApp(home: LoginScreen(authService: authService)));

    await tester.enterText(find.byType(TextField).at(0), 'user@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.tap(find.text('Zaloguj'));
    await tester.pumpAndSettle();

    verify(() => authService.signInWithEmail('user@test.com', 'secret')).called(1);
  });

  testWidgets('RegistrationScreen rejestruje użytkownika', (tester) async {
    final authService = MockRegisterAuthService();
    when(() => authService.register(any(), any(), any())).thenAnswer((_) async => Future.value());

    await tester.pumpWidget(MaterialApp(home: RegistrationScreen(authService: authService)));

    await tester.enterText(find.byType(TextField).at(0), 'user@test.com');
    await tester.enterText(find.byType(TextField).at(1), 'secret');
    await tester.enterText(find.byType(TextField).at(2), 'User');
    await tester.tap(find.text('Zarejestruj'));
    await tester.pumpAndSettle();

    verify(() => authService.register('user@test.com', 'secret', 'User')).called(1);
  });

  testWidgets('QuizListScreen ładuje quizy przy starcie', (tester) async {
    final quizService = MockQuizListService();
    when(() => quizService.getQuizList()).thenAnswer((_) async => []);

    await tester.pumpWidget(MaterialApp(home: QuizListScreen(quizListService: quizService)));
    await tester.pumpAndSettle();

    verify(() => quizService.getQuizList()).called(1);
  });

  testWidgets('ProfileScreen ładuje profil i osiągnięcia', (tester) async {
    final profileService = MockProfileDataService();
    final achievementService = MockAchievementService();

    when(() => profileService.getProfileData(any())).thenAnswer((_) async => Object());
    when(() => achievementService.getAchievements(any())).thenAnswer((_) async => []);

    await tester.pumpWidget(MaterialApp(
      home: ProfileScreen(
        profileDataService: profileService,
        achievementService: achievementService,
      ),
    ));
    await tester.pumpAndSettle();

    verify(() => profileService.getProfileData(any())).called(1);
    verify(() => achievementService.getAchievements(any())).called(1);
  });

  testWidgets('ScoreTableScreen ładuje dane wyniku', (tester) async {
    final scoreService = MockScoreTableService();
    when(() => scoreService.getGameData('session-1')).thenAnswer((_) async => Object());

    await tester.pumpWidget(MaterialApp(
      home: ScoreTableScreen(scoreTableService: scoreService, sessionId: 'session-1'),
    ));
    await tester.pumpAndSettle();

    verify(() => scoreService.getGameData('session-1')).called(1);
  });
}
