import 'package:flutter/material.dart';
import 'package:triviaapp/models/ui_options.dart';

class UserOptionsScreen extends StatefulWidget {
  UserOptionsScreen({
    super.key,
    UIOptions? options,
  }) : _options = options ?? UIOptions();

  final UIOptions _options;
  double _soundVolume = 50;
  double _musicVolume = 50;

  @override
  State<UserOptionsScreen> createState() => _UserOptionsScreenState();
}

class _UserOptionsScreenState extends State<UserOptionsScreen> {
  UIOptions get options => widget._options;
  double get soundVolume => widget._soundVolume;
  double get musicVolume => widget._musicVolume;
  set soundVolume(double v) => widget._soundVolume = v;
  set musicVolume(double v) => widget._musicVolume = v;

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