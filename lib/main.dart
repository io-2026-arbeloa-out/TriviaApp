import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:triviaapp/screens/main_menu_screen.dart';
import 'package:triviaapp/app_route.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(TriviaApp());
}

class TriviaApp extends StatelessWidget {
  const TriviaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trivia App',
      navigatorKey: AppRoute.instance.navigatorKey,
      initialRoute: AppRoute.loginScreen,//mainMenuScreen,
      onGenerateRoute: AppRoute.instance.onGenerateRoute,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: MainMenuScreen(),
    );
  }
}