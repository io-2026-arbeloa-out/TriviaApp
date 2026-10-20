import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:triviaapp/repositories/auth_repository.dart';
import 'package:triviaapp/repositories/profile_repository.dart';
import 'package:triviaapp/repositories/options_repository.dart';
import 'package:triviaapp/repositories/quiz_repository.dart';
import 'package:triviaapp/repositories/firebase_auth_repository.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';
import 'package:triviaapp/repositories/firebase_options_repository.dart';
import 'package:triviaapp/repositories/firebase_quiz_repository.dart';
import 'package:triviaapp/repositories/firebase_game_commands.dart';
import 'package:triviaapp/repositories/firebase_session_repository.dart';
import 'package:triviaapp/repositories/session_repository.dart';
import 'package:triviaapp/repositories/firebase_question_repository.dart';
import 'package:triviaapp/services/auth_register_service.dart';
import 'package:triviaapp/services/ui_options_service.dart';
import 'package:triviaapp/services/multiplayer_connection_service.dart';
import 'package:triviaapp/services/multiplayer_game_service.dart';
import 'package:triviaapp/services/singleplayer_game_service.dart';

class AppDependencies {
  static final instance = AppDependencies();

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final FirebaseDatabase? _database;
  final FirebaseFunctions? _functions;
  final AuthRepository? _authRepository;
  final ProfileRepository? _profileRepository;
  final OptionsRepository? _optionsRepository;
  final QuizRepository? _quizRepository;
  final SessionRepository? _sessionRepository;

  AppDependencies({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseDatabase? database,
    FirebaseFunctions? functions,
    AuthRepository? authRepository,
    ProfileRepository? profileRepository,
    OptionsRepository? optionsRepository,
    QuizRepository? quizRepository,
    SessionRepository? sessionRepository,
  }) : _auth = auth,
       _firestore = firestore,
       _database = database,
       _functions = functions,
       _authRepository = authRepository,
       _profileRepository = profileRepository,
       _optionsRepository = optionsRepository,
       _quizRepository = quizRepository,
       _sessionRepository = sessionRepository;

  late final firebaseAuth = _auth ?? FirebaseAuth.instance;
  late final firestore = _firestore ?? FirebaseFirestore.instance;
  late final database = _database ?? FirebaseDatabase.instance;

  late final AuthRepository authRepository =
      _authRepository ?? FirebaseAuthRepository(auth: firebaseAuth);
  late final ProfileRepository profileRepository =
      _profileRepository ??
      FirebaseProfileRepository(firestore: firestore, auth: firebaseAuth);
  late final OptionsRepository optionsRepository =
      _optionsRepository ??
      FirebaseOptionsRepository(firestore: firestore, auth: firebaseAuth);
  late final QuizRepository quizRepository =
      _quizRepository ?? FirebaseQuizRepository(firestore: firestore);
  late final uiOptionsService = UIOptionsService(
    optionsRepository,
    profileRepository,
  );
  late final gameCommands = FirebaseGameCommands(functions: _functions);
  late final SessionRepository sessionRepository =
      _sessionRepository ?? FirebaseSessionRepository(
        firestore: firestore,
        commands: gameCommands,
      );
  late final questionRepository = FirebaseQuestionRepository(
    database: database,
  );
  late final connectionService = MultiplayerConnectionService(
    sessionRepository: sessionRepository,
  );

  // Registration retries keep account state in one screen's service instance.
  AuthRegisterService createRegistrationService() => AuthRegisterService(
    authRepository: authRepository,
    profileRepository: profileRepository,
  );

  SingleplayerGameService createSingleplayerGameService() =>
      SingleplayerGameService(commands: gameCommands);

  MultiplayerGameService createMultiplayerGameService(
    String sessionId, {
    SessionRepository? sessions,
  }) => MultiplayerGameService(
    sessionId: sessionId,
    sessionRepository: sessions ?? sessionRepository,
    questionRepository: questionRepository,
    authRepository: authRepository,
    profileRepository: profileRepository,
  );
}
