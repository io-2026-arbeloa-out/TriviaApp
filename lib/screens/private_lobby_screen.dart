import 'package:flutter/material.dart';
import 'package:triviaapp/models/ui_options.dart';

class PrivateLobbyScreen extends StatelessWidget {
  PrivateLobbyScreen({
    super.key,
    UIOptions? options,
  }) : _options = options ?? UIOptions();

  final UIOptions _options;

  UIOptions get options => _options;

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
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Nagłówek
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      color: options.textColor,
                    ),
                    Text(
                      'Prywatne lobby',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(
                        color: options.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 24),

                // Placeholder na kod lobby
                Text(
                  'Kod pokoju: 1234',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: options.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),

                // Przyciski
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: options.mainButtonColor,
                    foregroundColor: options.textColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // TODO: utwórz prywatną grę
                  },
                  child: const Text(
                    'Utwórz grę',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: options.secondaryButtonColor,
                    foregroundColor: options.textColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // TODO: dołącz do gry po kodzie
                  },
                  child: const Text(
                    'Dołącz do gry',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const Spacer(),

                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Opuść lobby',
                    style: TextStyle(
                      color: options.textColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}