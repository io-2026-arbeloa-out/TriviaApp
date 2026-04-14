import 'package:flutter/material.dart';
import 'package:triviaapp/models/ui_options.dart';

class UserOptionsScreen extends StatefulWidget {
  const UserOptionsScreen({super.key});

  @override
  State<UserOptionsScreen> createState() => _UserOptionsScreenState();
}

class _UserOptionsScreenState extends State<UserOptionsScreen> {
  final UIOptions options = UIOptions();

  double soundVolume = 50;
  double musicVolume = 50;

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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back),
                      color: options.textColor,
                    ),
                    Text(
                      'Ustawienia dźwięku',
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

                Text(
                  'Głośność efektów',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: options.textColor,
                  ),
                ),
                Slider(
                  value: soundVolume,
                  min: 0,
                  max: 100,
                  activeColor: options.mainButtonColor,
                  inactiveColor:
                  options.mainButtonColor.withOpacity(0.3),
                  onChanged: (v) => setState(() => soundVolume = v),
                ),
                const SizedBox(height: 16),

                Text(
                  'Głośność muzyki',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: options.textColor,
                  ),
                ),
                Slider(
                  value: musicVolume,
                  min: 0,
                  max: 100,
                  activeColor: options.mainButtonColor,
                  inactiveColor:
                  options.mainButtonColor.withOpacity(0.3),
                  onChanged: (v) => setState(() => musicVolume = v),
                ),

                const Spacer(),

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
                    // TODO: zapisz UserOptions
                  },
                  child: const Text(
                    'Zapisz',
                    style: TextStyle(fontSize: 16),
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