import 'package:flutter/material.dart';
import 'package:triviaapp/screens/achievement_screen.dart';
import 'package:triviaapp/screens/leaderboard_screen.dart';
import 'package:triviaapp/screens/main_menu_screen.dart';
import 'package:triviaapp/screens/profile_screen.dart';
import 'package:triviaapp/screens/quiz_list_screen.dart';
import 'package:triviaapp/screens/singleplayer_game_screen.dart';
import 'package:triviaapp/services/quiz_list_service.dart';
import 'package:triviaapp/services/singleplayer_game_service.dart';

class AppRoute {
  AppRoute._();

  static final AppRoute instance = AppRoute._();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String loadingScreen = '/loading';
  static const String mainMenuScreen = '/';
  static const String profileScreen = '/profile';
  static const String quizListScreen = '/quizList';
  static const String leaderboardScreen = '/leaderboard';
  static const String achievementScreen = '/achievement';
  static const String singleplayer = '/singleplayer';

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case mainMenuScreen:
        return MaterialPageRoute(
          builder: (_) => MainMenuScreen(),
          settings: settings,
        );
      case profileScreen:
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(),
          settings: settings,
        );
      case quizListScreen:
        return MaterialPageRoute(
          builder: (_) => QuizListScreen(quizListService: QuizListService()),
          settings: settings,
        );
      case leaderboardScreen:
        return MaterialPageRoute(
          builder: (_) => LeaderboardScreen(),
          settings: settings,
        );
      case achievementScreen:
        return MaterialPageRoute(
          builder: (_) => AchievementScreen(),
          settings: settings,
        );
      case singleplayer:
        final category = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => SingleplayerGameScreen(
            category: category,
            singleplayerGameService: SingleplayerGameService(category: category),
          ),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => MainMenuScreen(),
          settings: settings,
        );
    }
  }


  void goToProfile() {
    navigatorKey.currentState?.pushNamed(profileScreen);
  }

  void goToQuizList() {
    navigatorKey.currentState?.pushNamed(quizListScreen);
  }

  void goToMainMenu() {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      mainMenuScreen,
          (route) => false,
    );
  }

  void goToLeaderboard() {
    navigatorKey.currentState?.pushNamed(leaderboardScreen);
  }

  void goToAchievements() {
    navigatorKey.currentState?.pushNamed(achievementScreen);
  }

  void goToSingleplayer(String quizId) {
    navigatorKey.currentState?.pushNamed(
      singleplayer,
      arguments: quizId,
    );
  }

  void goBack() {
    navigatorKey.currentState?.maybePop();
  }
}