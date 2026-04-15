import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/widgets/bottom_nav_bar.dart';

class MainMenuScreen extends StatelessWidget {
  MainMenuScreen({super.key});
  final UIOptions options = UIOptions();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              options.mainColor,
              options.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Prawy górny róg – przycisk ustawień (zębatka)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    onPressed: () {
                      // TODO: przejście do ekranu ustawień
                    },
                    icon: const Icon(Icons.settings),
                    color: options.secondaryButtonColor,
                    tooltip: 'Ustawienia',
                  ),
                ),
              ),

              // Główna zawartość – logo, nazwa aplikacji, przyciski
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.quiz,
                      size: 100,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 30),

                    // Nazwa aplikacji
                    Text(
                      'Trivia App',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: options.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sprawdź swoją wiedzę!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: options.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),

                    // Przycisk Singleplayer
                    SizedBox(
                      width: 220,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: options.mainButtonColor,
                          foregroundColor: options.textColor,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          AppRoute.instance.goToSingleplayer('general');
                        },
                        child: const Text(
                          'Singleplayer',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Przycisk Multiplayer
                    SizedBox(
                      width: 220,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: options.mainButtonColor,
                          foregroundColor: options.textColor,
                          padding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          // TODO: przejście do trybu multiplayer
                        },
                        child: const Text(
                          'Multiplayer',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
        bottomNavigationBar: const AppBottomNavigationBar(currentIndex: 1),
    );
  }
}