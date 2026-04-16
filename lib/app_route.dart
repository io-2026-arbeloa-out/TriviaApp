import 'package:flutter/material.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/screens/achievement_screen.dart';
import 'package:triviaapp/screens/game_options_screen.dart';
import 'package:triviaapp/screens/leaderboard_screen.dart';
import 'package:triviaapp/screens/login_screen.dart';
import 'package:triviaapp/screens/main_menu_screen.dart';
import 'package:triviaapp/screens/multiplayer_game_screen.dart';
import 'package:triviaapp/screens/private_lobby_screen.dart';
import 'package:triviaapp/screens/profile_screen.dart';
import 'package:triviaapp/screens/quiz_list_screen.dart';
import 'package:triviaapp/screens/registration_screen.dart';
import 'package:triviaapp/screens/score_table_screen.dart';
import 'package:triviaapp/screens/singleplayer_game_screen.dart';
import 'package:triviaapp/screens/user_options_screen.dart';
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
  static const String singleplayerScreen = '/singleplayer';
  static const String multiplayerScreen = '/multiplayer';
  static const String loginScreen = '/login';
  static const String registrationScreen = '/registration';
  static const String gameOptionsScreen = '/gameOptions';
  static const String userOptionsScreen = '/userOptions';
  static const String scoreTableScreen = '/scoreTable';
  static const String privateLobbyScreen = '/privateLobby';

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
      case singleplayerScreen:
        final category = settings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => SingleplayerGameScreen(
            category: category,
            singleplayerGameService: SingleplayerGameService(category: category),
          ),
          settings: settings,
        );
      case multiplayerScreen:
        return MaterialPageRoute(
          builder: (_) => MultiplayerGameScreen(),
          settings: settings,
        );
      case loginScreen:
        return MaterialPageRoute(
          builder: (_) => LoginScreen(),
          settings: settings,
        );
      case registrationScreen:
        final options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => RegistrationScreen(
            options: options,
          ),
          settings: settings,
        );
      case gameOptionsScreen:
        return MaterialPageRoute(
          builder: (_) => GameOptionsScreen(),
          settings: settings,
        );
      case userOptionsScreen:
        return MaterialPageRoute(
          builder: (_) => UserOptionsScreen(),
          settings: settings,
        );
      case scoreTableScreen:
        return MaterialPageRoute(
          builder: (_) => ScoreTableScreen(),
          settings: settings,
        );
      case privateLobbyScreen:
        return MaterialPageRoute(
          builder: (_) => PrivateLobbyScreen(),
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
      singleplayerScreen,
      arguments: quizId,
    );
  }

  void goToMultiplayer() {
    navigatorKey.currentState?.pushNamed(multiplayerScreen);
  }

  void goToRegistration(UIOptions options) {
    navigatorKey.currentState?.pushNamed(
      registrationScreen,
      arguments: options,
    );
  }

  void goToLogin() {
    navigatorKey.currentState?.pushNamed(loginScreen);
  }

  void goToUserOptions() {
    navigatorKey.currentState?.pushNamed(userOptionsScreen);
  }

  void goToGameOptions() {
    navigatorKey.currentState?.pushNamed(gameOptionsScreen);
  }

  void goToScoreTable() {
    navigatorKey.currentState?.pushNamed(scoreTableScreen);
  }

  void goToPrivateLobby() {
    navigatorKey.currentState?.pushNamed(privateLobbyScreen);
  }

  void goBack() {
    navigatorKey.currentState?.maybePop();
  }
}