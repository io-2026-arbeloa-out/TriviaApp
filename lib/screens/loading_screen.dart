import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/audio_manager.dart';
import 'package:triviaapp/interfaces/i_ui_options_service.dart';
import 'package:triviaapp/interfaces/i_user_options_service.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/models/user_options.dart';
import 'package:triviaapp/services/ui_options_service.dart';
import 'package:triviaapp/services/user_options_service.dart';

class LoadingScreen extends StatefulWidget {
  LoadingScreen({
    super.key,
    bool? isLoggedIn,
    IUIOptionsService? uiService,
    IUserOptionsService? userService,
  })  : _isLoggedIn = isLoggedIn ?? false,
        _uiService = uiService ?? UIOptionsService(),
        _userService = userService ?? UserOptionsService();

  final bool _isLoggedIn;
  final IUIOptionsService _uiService;
  final IUserOptionsService _userService;

  bool get isLoggedIn => _isLoggedIn;
  IUIOptionsService get uiService => _uiService;
  IUserOptionsService get userService => _userService;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late UIOptions _uiOptions;
  late UserOptions _userOptions;
  final UIOptions _defaultOptions = const UIOptions();


  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadAssets();
    if (!mounted) return;
    await AudioManager.instance.init(_userOptions);
    AppRoute.instance.goToMainMenu(isLoggedIn: widget.isLoggedIn, options: _uiOptions);
  }

  Future<void> _loadAssets() async {
    await _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      _uiOptions = await widget.uiService.getUIOptions();
    } catch (e) {
      _uiOptions = const UIOptions();
    }
    try {
      _userOptions = await widget.userService.getUserOptions();
    } catch (e) {
      _userOptions = const UserOptions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _defaultOptions.mainColor,
              _defaultOptions.secondaryColor,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.quiz, size: 80, color: _defaultOptions.textColor),
                const SizedBox(height: 16),
                Text(
                  'Ładowanie...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: _defaultOptions.textColor,
                  ),
                ),
                const SizedBox(height: 16),
                CircularProgressIndicator(color: _defaultOptions.textColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}