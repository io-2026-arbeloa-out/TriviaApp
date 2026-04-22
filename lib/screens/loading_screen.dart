import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/interfaces/i_ui_options_service.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/screens/main_menu_screen.dart';
import 'package:triviaapp/services/ui_options_service.dart';

class LoadingScreen extends StatefulWidget {
  LoadingScreen({
    super.key,
    bool? isLoggedIn,
    IUIOptionsService? service,
  })  : _isLoggedIn = isLoggedIn ?? false,
        _service = service ?? UIOptionsService();

  final bool _isLoggedIn;
  final IUIOptionsService _service;

  bool get isLoggedIn => _isLoggedIn;
  IUIOptionsService get service => _service;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late UIOptions _options;
  final UIOptions _defaultOptions = const UIOptions();


  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadAssets();
    if (!mounted) return;
    AppRoute.instance.goToMainMenu(isLoggedIn: widget.isLoggedIn, options: _options);
  }

  Future<void> _loadAssets() async {
    await _loadOptions();
  }

  Future<void> _loadOptions() async {
    try {
      _options = await widget.service.getUIOptions();
    } catch (e) {
      _options = const UIOptions();
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