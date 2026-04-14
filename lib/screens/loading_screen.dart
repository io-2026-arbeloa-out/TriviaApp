import 'package:flutter/material.dart';
import 'package:triviaapp/models/ui_options.dart';

class LoadingScreen extends StatelessWidget {
  LoadingScreen({super.key});

  final UIOptions options = UIOptions();

  @override
  Widget build(BuildContext context) {
    // TODO: w praktyce tutaj wywołasz _loadAssets() i przejdziesz do next screen
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
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.quiz,
                  size: 80,
                  color: options.textColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Ładowanie...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: options.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                const CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}