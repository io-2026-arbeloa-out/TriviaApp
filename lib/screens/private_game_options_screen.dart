import 'package:flutter/material.dart';
import 'package:triviaapp/models/ui_options.dart';

class PrivateGameOptionsScreen extends StatelessWidget {
  PrivateGameOptionsScreen({
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
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
                      'Opcje gry',
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

                // Tu dodasz swoje pola formularza (czas na pytanie, ilość graczy, itp.)
                Text(
                  'Konfiguracja prywatnej gry',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: options.textColor,
                  ),
                ),
                const SizedBox(height: 16),

                // Placeholder pól
                _buildTextField(context, 'Czas na pytanie (s)'),
                const SizedBox(height: 12),
                _buildTextField(context, 'Maks. liczba graczy'),
                const SizedBox(height: 12),
                _buildTextField(context, 'Kategoria'),

                const Spacer(),

                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: options.mainButtonColor,
                          foregroundColor: options.textColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          // TODO: zapisz opcje
                        },
                        child: const Text(
                          'Zapisz',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: options.textColor,
                          side: BorderSide(
                            color: options.secondaryButtonColor,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Anuluj',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(BuildContext context, String label) {
    return TextField(
      style: TextStyle(color: options.textColor),
      cursorColor: options.textColor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: options.textColor.withOpacity(0.8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: options.textColor.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: options.textColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.1),
      ),
    );
  }
}