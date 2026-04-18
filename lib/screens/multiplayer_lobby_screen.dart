import 'package:flutter/material.dart';
import 'package:triviaapp/models/ui_options.dart';

class MultiplayerLobbyScreen extends StatelessWidget {
  MultiplayerLobbyScreen({
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
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Łączenie z lobby rankingowym...',
                    textAlign: TextAlign.center,
                    style:
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: options.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Oczekiwanie na innych graczy',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(
                      color: options.textColor,
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Opuść lobby',
                      style: TextStyle(color: options.textColor),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}