import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/interfaces/i_register_auth_service.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/repositories/firebase_auth_repository.dart';
import 'package:triviaapp/repositories/firebase_profile_repository.dart';
import 'package:triviaapp/services/auth_register_service.dart';

class RegistrationScreen extends StatefulWidget {
  final IRegisterAuthService _authService;
  final UIOptions _options;

  RegistrationScreen({
    super.key,
    UIOptions? options,
    IRegisterAuthService? authService,
  })  : _options = options ?? UIOptions(),
        _authService = authService ?? AuthRegisterService(
          authRepository: FirebaseAuthRepository(),
          profileRepository: FirebaseProfileRepository(),
        );

  IRegisterAuthService get authService => _authService;
  UIOptions get options => _options;

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _onClickRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty || username.isEmpty) {
      _showMessage('Wypelnij wszystkie pola.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.authService.register(email, password, username);
      if (!mounted) return;
      AppRoute.instance.goToMainMenu(false, widget.options);
    } on FirebaseAuthException catch (e) {
      _showMessage(_mapFirebaseError(e.code));
    } catch (_) {
      _showMessage('Wystapil nieoczekiwany blad.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onClickClose() => AppRoute.instance.goBack();

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Ten adres email jest juz zajety.';
      case 'weak-password':
        return 'Haslo jest za slabe (min. 6 znakow).';
      case 'invalid-email':
        return 'Nieprawidlowy adres email.';
      default:
        return 'Blad rejestracji: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;

    return Scaffold(
      backgroundColor: options.secondaryColor,
      appBar: AppBar(
        backgroundColor: options.mainColor,
        title: Text(
          'Rejestracja',
          style: TextStyle(color: options.textColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: options.textColor),
          onPressed: _onClickClose,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _usernameController,
              style: TextStyle(color: options.textColor),
              decoration: InputDecoration(
                labelText: 'Nazwa uzytkownika',
                labelStyle: TextStyle(color: options.textColor),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailController,
              style: TextStyle(color: options.textColor),
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: options.textColor),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              style: TextStyle(color: options.textColor),
              decoration: InputDecoration(
                labelText: 'Haslo',
                labelStyle: TextStyle(color: options.textColor),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: options.mainButtonColor,
                foregroundColor: options.textColor,
              ),
              onPressed: _onClickRegister,
              child: const Text('Zarejestruj'),
            ),
          ],
        ),
      ),
    );
  }
}