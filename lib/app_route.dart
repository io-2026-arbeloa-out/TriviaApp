import 'package:flutter/material.dart';
import 'package:triviaapp/models/multiplayer_session_data.dart';
import 'package:triviaapp/models/game_route_arguments.dart';
import 'package:triviaapp/models/singleplayer_session_data.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/screens/achievement_screen.dart';
import 'package:triviaapp/screens/private_game_options_screen.dart';
import 'package:triviaapp/screens/leaderboard_screen.dart';
import 'package:triviaapp/screens/loading_screen.dart';
import 'package:triviaapp/screens/login_screen.dart';
import 'package:triviaapp/screens/main_menu_screen.dart';
import 'package:triviaapp/interfaces/i_multiplayer_game_service.dart';
import 'package:triviaapp/screens/multiplayer_game_screen.dart';
import 'package:triviaapp/screens/multiplayer_score_table_screen.dart';
import 'package:triviaapp/screens/private_lobby_screen.dart';
import 'package:triviaapp/screens/profile_screen.dart';
import 'package:triviaapp/screens/quiz_list_screen.dart';
import 'package:triviaapp/screens/registration_screen.dart';
import 'package:triviaapp/screens/singleplayer_score_table_screen.dart';
import 'package:triviaapp/screens/singleplayer_game_screen.dart';
import 'package:triviaapp/screens/singleplayer_options_screen.dart';
import 'package:triviaapp/screens/user_options_screen.dart';
import 'package:triviaapp/app_dependencies.dart';

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
  static const String privateGameOptionsScreen = '/privateGameOptions';
  static const String userOptionsScreen = '/userOptions';
  static const String singleplayerScoreTableScreen = '/singleplayerScoreTable';
  static const String privateLobbyScreen = '/privateLobby';
  static const String multiplayerScoreTableScreen = '/multiplayerScoreTable';

  Route<dynamic>? onGenerateRoute(RouteSettings settings, {AppDependencies? dependencies}) {
    final deps = dependencies ?? AppDependencies.instance;
    switch (settings.name) {
      case mainMenuScreen:
        final UIOptions? options = settings.arguments as UIOptions?;
        return MaterialPageRoute(
          builder: (_) =>
              MainMenuScreen(options: options, dependencies: deps),
          settings: settings,
        );

      case profileScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => ProfileScreen(options: options,
            profileRepository: deps.profileRepository, authRepository: deps.authRepository),
          settings: settings,
        );

      case quizListScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => QuizListScreen(
            quizRepository: deps.quizRepository,
            options: options,
          ),
          settings: settings,
        );

      case loadingScreen:
        return MaterialPageRoute(
          builder: (_) => LoadingScreen(uiService: deps.uiOptionsService, optionsRepository: deps.optionsRepository),
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
        final args = settings.arguments as SingleplayerSessionArguments;
        final options = args.options;
        final sessionData = args.sessionData;
        return MaterialPageRoute(
          builder: (_) => SingleplayerGameScreen(
            options: options,
            sessionData: sessionData,
            gameService: deps.createSingleplayerGameService(),
          ),
          settings: settings,
        );

      case singleplayerOptionsScreen:
        final args = settings.arguments as SingleplayerOptionsArguments;
        final category = args.category;
        final options = args.options;
        return MaterialPageRoute(
          builder: (_) => SingleplayerOptionsScreen(category: category, options: options),
          settings: settings,
        );

      case multiplayerGameScreen:
        final args = settings.arguments as MultiplayerGameArguments;
        final options = args.options;
        final gameService = args.gameService;
        return MaterialPageRoute(
          builder: (_) => MultiplayerGameScreen(
            options: options,
            gameService: gameService,
          ),
          settings: settings,
        );

      case loginScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => LoginScreen(options: options, authRepository: deps.authRepository),
          settings: settings,
        );

      case registrationScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => RegistrationScreen(options: options, authService: deps.createRegistrationService()),
          settings: settings,
        );

      case privateGameOptionsScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => PrivateGameOptionsScreen(options: options, dependencies: deps),
          settings: settings,
        );

      case userOptionsScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => UserOptionsScreen(options: options,
            optionsRepository: deps.optionsRepository, uiOptionsService: deps.uiOptionsService),
          settings: settings,
        );

      case singleplayerScoreTableScreen:
        final args = settings.arguments as SingleplayerSessionArguments;
        final options = args.options;
        final sessionData = args.sessionData;
        return MaterialPageRoute(
          builder: (_) => SingleplayerScoreTableScreen(
            options: options,
            sessionData: sessionData,
          ),
          settings: settings,
        );

      case privateLobbyScreen:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) => PrivateLobbyScreen(options: options, dependencies: deps),
          settings: settings,
        );

      case multiplayerScoreTableScreen:
        final args = settings.arguments as MultiplayerScoreArguments;
        final options = args.options;
        final session = args.session;
        final myUid = args.myUid;
        return MaterialPageRoute(
          builder: (_) => MultiplayerScoreTableScreen(
            options: options,
            session: session,
            myUid: myUid,
          ),
          settings: settings,
        );

      default:
        final UIOptions options = settings.arguments as UIOptions;
        return MaterialPageRoute(
          builder: (_) =>
              MainMenuScreen(options: options, dependencies: deps),
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

  void goToSingleplayerGame(UIOptions options, SingleplayerSessionData sessionData) {
    navigatorKey.currentState?.pushNamed(
      singleplayerGameScreen,
      arguments: SingleplayerSessionArguments(options, sessionData),
    );
  }

  void goToSingleplayerOptions(String quizId, UIOptions options) {
    navigatorKey.currentState?.pushNamed(
      singleplayerOptionsScreen,
      arguments: SingleplayerOptionsArguments(quizId, options),
    );
  }

  void goToMultiplayer(
    UIOptions options,
    IMultiplayerGameService gameService,
  ) {
    navigatorKey.currentState?.pushReplacementNamed(
      multiplayerGameScreen,
      arguments: MultiplayerGameArguments(options, gameService),
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
      privateGameOptionsScreen,
      arguments: options,
    );
  }

  void goToSingleplayerScoreTable(
      UIOptions options,
      SingleplayerSessionData sessionData,
      ) {
    navigatorKey.currentState?.pushNamed(
      singleplayerScoreTableScreen,
      arguments: SingleplayerSessionArguments(options, sessionData),
    );
  }

  void goToPrivateLobby(UIOptions options) {
    navigatorKey.currentState?.pushNamed(
      privateLobbyScreen,
      arguments: options,
    );
  }

  void goToMultiplayerScoreTable({
    required UIOptions options,
    required MultiplayerSessionData session,
    required String myUid,
  }) {
    navigatorKey.currentState?.pushReplacementNamed(
      multiplayerScoreTableScreen,
      arguments: MultiplayerScoreArguments(options, session, myUid),
    );
  }

  void goBack() {
    navigatorKey.currentState?.maybePop();
  }
}
