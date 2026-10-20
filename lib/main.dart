import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:triviaapp/app_dependencies.dart';
import 'firebase_options.dart';
import 'package:triviaapp/app_route.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(TriviaApp());
}

class TriviaApp extends StatelessWidget {
  const TriviaApp({super.key, this.dependencies});

  final AppDependencies? dependencies;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trivia App',
      navigatorKey: AppRoute.instance.navigatorKey,
      initialRoute: AppRoute.loadingScreen,
      onGenerateRoute: (settings) => AppRoute.instance.onGenerateRoute(settings, dependencies: dependencies),
      debugShowCheckedModeBanner: false,
    );
  }
}
