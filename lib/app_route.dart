import 'package:flutter/material.dart';
import 'package:triviaapp/models/singleplayer_game_options.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/screens/achievement_screen.dart';
import 'package:triviaapp/screens/game_options_screen.dart';
import 'package:triviaapp/screens/leaderboard_screen.dart';
import 'package:triviaapp/screens/loading_screen.dart';
import 'package:triviaapp/screens/login_screen.dart';
import 'package:triviaapp/screens/main_menu_screen.dart';
import 'package:triviaapp/screens/multiplayer_game_screen.dart';
import 'package:triviaapp/screens/private_lobby_screen.dart';
import 'package:triviaapp/screens/profile_screen.dart';
import 'package:triviaapp/screens/quiz_list_screen.dart';
import 'package:triviaapp/screens/registration_screen.dart';
import 'package:triviaapp/screens/score_table_screen.dart';
import 'package:triviaapp/screens/singleplayer_game_screen.dart';
import 'package:triviaapp/screens/singleplayer_options_screen.dart';
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
  static const String singleplayerGameScreen = '/singleplayerGame';
  static const String singleplayerOptionsScreen = '/singleplayerOptions';
  static const String multiplayerGameScreen = '/multiplayerGame';
  static const String loginScreen = '/login';
  static const String registrationScreen = '/registration';
  static const String gameOptionsScreen = '/gameOptions';
  static const String userOptionsScreen = '/userOptions';
  static const String scoreTableScreen = '/scoreTable';
  static const String privateLobbyScreen = '/privateLobby';

  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case mainMenuScreen:
        final UIOptions? options = settings.arguments as UIOptions?;
        return MaterialPageRoute(
          builder: (_) =>
              MainMenuScreen(options: options),
          settings: settings,
        );

      case profileScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(options: options),
          settings: settings,
        );

      case quizListScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => QuizListScreen(
            quizListService: QuizListService(),
            options: options,
          ),
          settings: settings,
        );

      case loadingScreen:
        return MaterialPageRoute(
          builder: (_) => LoadingScreen(),
          settings: settings,
        );

      case leaderboardScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => LeaderboardScreen(options: options),
          settings: settings,
        );

      case achievementScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => AchievementScreen(options: options),
          settings: settings,
        );

      case singleplayerGameScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final String category = args['category'];
        final UIOptions options = args['options'];
        final SingleplayerGameOptions gameOptions = args['gameOptions'];
        return MaterialPageRoute(
          builder: (_) => SingleplayerGameScreen(
            category: category,
            options: options,
            gameOptions: gameOptions,
          ),
          settings: settings,
        );

      case singleplayerOptionsScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final String category = args['category'];
        final UIOptions options = args['options'];
        return MaterialPageRoute(
          builder: (_) => SingleplayerOptionsScreen(category: category, options: options),
          settings: settings,
        );

      case multiplayerGameScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => MultiplayerGameScreen(options: options),
          settings: settings,
        );

      case loginScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => LoginScreen(options: options),
          settings: settings,
        );

      case registrationScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => RegistrationScreen(options: options),
          settings: settings,
        );

      case gameOptionsScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => GameOptionsScreen(options: options),
          settings: settings,
        );

      case userOptionsScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => UserOptionsScreen(options: options),
          settings: settings,
        );

      case scoreTableScreen:
        final args = settings.arguments as Map<String, dynamic>;
        final List<bool> results = args['results'];
        final UIOptions options = args['options'];
        return MaterialPageRoute(
          builder: (_) => ScoreTableScreen(options: options, results: results),
          settings: settings,
        );

      case privateLobbyScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => PrivateLobbyScreen(options: options),
          settings: settings,
        );

      default:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) =>
              MainMenuScreen(options: options),
          settings: settings,
        );
    }
  }

  void goToProfile(UIOptions options) {
    navigatorKey.currentState?.pushNamed(
      profileScreen,
      arguments: options,
    );
  }

  void goToQuizList(UIOptions options) {
    navigatorKey.currentState?.pushNamed(
      quizListScreen,
      arguments: options,
    );
  }

  void goToMainMenu(UIOptions options) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      mainMenuScreen,
      arguments: options,
          (route) => false,
    );
  }

  void goToLeaderboard(UIOptions options) {
    navigatorKey.currentState?.pushNamed(
      leaderboardScreen,
      arguments: options,
    );
  }

  void goToAchievements(UIOptions options) {
    navigatorKey.currentState?.pushNamed(
      achievementScreen,
      arguments: options,
    );
  }

  void goToSingleplayerGame(String quizId, UIOptions options, SingleplayerGameOptions gameOptions) {
    navigatorKey.currentState?.pushNamed(
      singleplayerGameScreen,
      arguments: {
        'category': quizId,
        'options': options,
        'gameOptions': gameOptions,
      },
    );
  }

  void goToSingleplayerOptions(String quizId, UIOptions options) {
    navigatorKey.currentState?.pushNamed(
      singleplayerOptionsScreen,
      arguments: {
        'category': quizId,
        'options': options,
      },
    );
  }

  void goToMultiplayer(UIOptions options) {
    navigatorKey.currentState?.pushNamed(
      multiplayerGameScreen,
      arguments: options,
    );
  }

  void goToRegistration(UIOptions options) {
    navigatorKey.currentState?.pushNamed(
      registrationScreen,
      arguments: options,
    );
  }

  void goToLogin(UIOptions options) {
    navigatorKey.currentState?.pushNamed(
      loginScreen,
      arguments: options,
    );
  }

  void goToUserOptions(UIOptions options) {
    navigatorKey.currentState?.pushNamed(
      userOptionsScreen,
      arguments: options,
    );
  }

  void goToGameOptions(UIOptions options) {
    navigatorKey.currentState?.pushNamed(
      gameOptionsScreen,
      arguments: options,
    );
  }

  void goToScoreTable(UIOptions options, List<bool> results) {
    navigatorKey.currentState?.pushNamed(
      scoreTableScreen,
      arguments: {
        'options': options,
        'results': results,
      },
    );
  }

  void goToPrivateLobby(UIOptions options) {
    navigatorKey.currentState?.pushNamed(
      privateLobbyScreen,
      arguments: options,
    );
  }

  void goBack() {
    navigatorKey.currentState?.maybePop();
  }
}