import 'package:flutter/material.dart';
import 'package:triviaapp/models/ui_options.dart';

class MultiplayerGameScreen extends StatelessWidget {
  MultiplayerGameScreen({
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
                // Pasek górny
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                      color: options.textColor,
                    ),
                    Text(
                      'Multiplayer',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                        color: options.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 16),

                // Informacje o graczach (placeholder)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: options.secondaryColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Gracze: 1/4',
                        style: TextStyle(color: options.textColor),
                      ),
                      const Spacer(),
                      Text(
                        'Runda 1/10',
                        style: TextStyle(color: options.textColor),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Pytanie
                Text(
                  'Treść pytania multiplayer.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: options.textColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Odpowiedzi
                for (int i = 0; i < 4; i++) ...[
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: options.mainButtonColor,
                        foregroundColor: options.textColor,
                        padding:
                        const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        // TODO: obsługa odpowiedzi multiplayer
                      },
                      child: Text('Odpowiedź ${i + 1}'),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}