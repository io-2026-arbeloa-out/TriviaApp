import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/audio_manager.dart';
import 'package:triviaapp/models/difficulty.dart';
import 'package:triviaapp/models/online_game_options.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/screens/multiplayer_lobby_screen.dart';
import 'package:triviaapp/screens/private_lobby_screen.dart';
import 'package:triviaapp/widgets/bottom_nav_bar.dart';
import 'package:triviaapp/widgets/login_register_pop_up.dart';

class MainMenuScreen extends StatefulWidget {
  MainMenuScreen({
    super.key,
    UIOptions? options,
    bool Function()? authChecker,
  }) : _authChecker =
      authChecker ?? (() => FirebaseAuth.instance.currentUser != null),
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
    //AudioManager.instance.playMusicForScreen(AppRoute.mainMenuScreen);
  }

  void _onPopupClose() {
    setState(() => _popupDismissed = true);
  }

  void _showJoinDialog() {
    final controller = TextEditingController();
    String? errorText;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: widget.options.secondaryColor,
          title: Text(
            'Dołącz do gry',
            style: TextStyle(
              color: widget.options.textColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            maxLength: 6,
            style: TextStyle(color: widget.options.textColor),
            cursorColor: widget.options.textColor,
            decoration: InputDecoration(
              labelText: 'Kod pokoju',
              labelStyle: TextStyle(
                color: widget.options.textColor.withOpacity(0.7),
              ),
              errorText: errorText,
              counterStyle: TextStyle(
                color: widget.options.textColor.withOpacity(0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(
                  color: widget.options.textColor.withOpacity(0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: widget.options.textColor),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(
                'Anuluj',
                style: TextStyle(
                  color: widget.options.textColor.withOpacity(0.7),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                final text = controller.text.trim();
                final code = int.tryParse(text);
                if (code == null || text.length != 6) {
                  setDialogState(
                        () => errorText = 'Wpisz prawidłowy 6-cyfrowy kod',
                  );
                  return;
                }
                Navigator.of(ctx).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => PrivateLobbyScreen(
                      options: widget.options,
                      code: code,
                    ),
                  ),
                );
              },
              child: Text(
                'Dołącz',
                style: TextStyle(
                  color: widget.options.mainButtonColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
                        onPressed: _showJoinDialog,
                        child: const Text(
                          'Dołącz do gry',
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
                        onPressed: () =>
                            AppRoute.instance.goToGameOptions(widget.options),
                        child: const Text(
                          'Utwórz grę',
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
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => MultiplayerLobbyScreen(
                                uid: FirebaseAuth.instance.currentUser?.uid ??
                                    'uid1',
                                username:
                                FirebaseAuth.instance.currentUser
                                    ?.displayName ??
                                    'test',
                                settings: const OnlineGameOptions(
                                  categoryId: 'general',
                                  maxPlayers: 2,//todo
                                  difficulty: Difficulty.random,
                                ),
                                options: widget.options,
                              ),
                            ),
                          );
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