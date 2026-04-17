import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/interfaces/i_ui_options_service.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/screens/login_screen.dart';
import 'package:triviaapp/screens/registration_screen.dart';
import 'package:triviaapp/services/ui_options_service.dart';
import 'package:triviaapp/widgets/bottom_nav_bar.dart';
import 'package:triviaapp/widgets/login_register_pop_up.dart';

class MainMenuScreen extends StatefulWidget {
  MainMenuScreen({
    super.key,
    bool? isLoggedIn,
    IUIOptionsService? service,
  }) : _service = service ?? UIOptionsService(),
       _isLoggedIn = isLoggedIn ?? false;

  final bool _isLoggedIn;
  final IUIOptionsService _service;

  bool get isLoggedIn => _isLoggedIn;

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  late UIOptions _options;
  bool _loaded = false;

  bool _popupDismissed = false;

  bool get _showPopup => !widget.isLoggedIn && !_popupDismissed;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      final options = await widget._service.getUIOptions();
      setState(() {
        _options = options;
        _loaded = true;
      });
    } catch (e) {
      setState(() {
        _options = UIOptions();
        _loaded = true;
      });
    }
  }

  void _onLoginPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  void _onRegisterPressed() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => RegistrationScreen()),
    );
  }

  void _onPopupClose() {
    setState(() => _popupDismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_options.mainColor, _options.secondaryColor],
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
                      // TODO: przejście do ekranu ustawień
                    },
                    icon: const Icon(Icons.settings),
                    color: _options.secondaryButtonColor,
                    tooltip: 'Ustawienia',
                  ),
                ),
              ),
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.quiz, size: 100, color: Colors.white),
                    const SizedBox(height: 30),
                    Text(
                      'Trivia App',
                      style: Theme.of(context)
                          .textTheme
                          .headlineMedium
                          ?.copyWith(
                        color: _options.textColor,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sprawdź swoją wiedzę!',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _options.textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: 220,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _options.mainButtonColor,
                          foregroundColor: _options.textColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
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
                    SizedBox(
                      width: 220,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _options.mainButtonColor,
                          foregroundColor: _options.textColor,
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
          color: _options.secondaryColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_showPopup)
                LoginRegisterPopUp(
                  options: _options,
                  onLogin: _onLoginPressed,
                  onRegister: _onRegisterPressed,
                  onClose: _onPopupClose,
                ),
              AppBottomNavigationBar(
                currentIndex: 1,
                options: _options,
              ),
            ],
          ),
        ),
    );
  }
}