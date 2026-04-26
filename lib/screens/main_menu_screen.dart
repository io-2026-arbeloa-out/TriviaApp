import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/audio_manager.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/widgets/bottom_nav_bar.dart';
import 'package:triviaapp/widgets/login_register_pop_up.dart';

class MainMenuScreen extends StatefulWidget {
  MainMenuScreen({
    super.key,
    UIOptions? options,
    bool Function()? authChecker,
  }) : _authChecker = authChecker ?? (() => FirebaseAuth.instance.currentUser != null),
       _options = options ?? UIOptions();

  final UIOptions _options;
  final bool Function() _authChecker;

  UIOptions get options => _options;
  Function() get authChecker => _authChecker;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {

  bool _popupDismissed = false;

  bool get _showPopup => !widget.authChecker() && !_popupDismissed;

  @override
  void initState() {
    super.initState();
    //AudioManager.instance.playMusicForScreen(AppRoute.mainMenuScreen); //todo jedna z opcji ale szkoda gadac
  }

  void _onPopupClose() {
    setState(() => _popupDismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [widget.options.mainColor, widget.options.secondaryColor],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: IconButton(
                    onPressed: () {
                      AppRoute.instance.goToUserOptions(widget.options);
                    },
                    icon: const Icon(Icons.settings),
                    color: widget.options.textColor,
                    tooltip: 'Ustawienia',
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz, size: 100, color: widget.options.textColor),
                    const SizedBox(height: 30),
                    Text(
                      'Trivia App',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                        color: widget.options.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sprawdź swoją wiedzę!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: widget.options.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 220,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.options.mainButtonColor,
                          foregroundColor: widget.options.textColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          /*AppRoute.instance.goToSingleplayer(
                              'general',
                              widget.options
                          );*///todo zmiana na private game
                        },
                        child: const Text(
                          'Singleplayer',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 220,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.options.mainButtonColor,
                          foregroundColor: widget.options.textColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
        bottomNavigationBar: Container(
          color: widget.options.secondaryColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showPopup)
                LoginRegisterPopUp(
                  options: widget.options,
                  onClose: _onPopupClose,
                ),
              AppBottomNavigationBar(
                currentIndex: 1,
                options: widget.options,
              ),
            ],
          ),
        ),
    );
  }
}