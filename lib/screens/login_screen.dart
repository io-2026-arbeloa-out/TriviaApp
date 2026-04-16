import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:triviaapp/interfaces/i_login_auth_service.dart';
import 'package:triviaapp/models/ui_options.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/repositories/firebase_auth_repository.dart';
import 'package:triviaapp/services/auth_login_service.dart';

class LoginScreen extends StatefulWidget {
  final ILoginAuthService _authService;
  final UIOptions _options;

  LoginScreen({
    super.key,
    UIOptions? options,
    ILoginAuthService? authService,
  })  : _options = options ?? UIOptions(),
        _authService = authService ?? AuthLoginService(
          authRepository: FirebaseAuthRepository(),
        );

  ILoginAuthService get authService => _authService;
  UIOptions get options => _options;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onClickLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showMessage('Wypelnij wszystkie pola.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.authService.signInWithEmail(email, password);
      if (!mounted) return;
      AppRoute.instance.goToMainMenu();
    } on FirebaseAuthException catch (e) {
      _showMessage(_mapFirebaseError(e.code));
    } catch (_) {
      _showMessage('Wystapil nieoczekiwany blad.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onClickOpenRegister() {
    AppRoute.instance.goToRegistration(
          widget.options,
        );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nie znaleziono uzytkownika.';
      case 'wrong-password':
        return 'Nieprawidlowe haslo.';
      case 'invalid-email':
        return 'Nieprawidlowy adres email.';
      default:
        return 'Blad logowania: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.options.mainColor,
      appBar: AppBar(
        title: Text(
          'Logowanie',
          style: TextStyle(color: widget.options.textColor),
        ),
        backgroundColor: widget.options.secondaryColor,
        iconTheme: IconThemeData(color: widget.options.textColor),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: widget.options.textColor),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: widget.options.secondaryColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: widget.options.mainButtonColor),
                ),
              ),
              style: TextStyle(color: widget.options.textColor),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Haslo',
                labelStyle: TextStyle(color: widget.options.textColor),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: widget.options.secondaryColor),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: widget.options.mainButtonColor),
                ),
              ),
              style: TextStyle(color: widget.options.textColor),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? CircularProgressIndicator(
              color: widget.options.mainButtonColor,
            )
                : ElevatedButton(
              onPressed: _onClickLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: widget.options.mainButtonColor,
                foregroundColor: widget.options.textColor,
                padding: const EdgeInsets.symmetric(
                  horizontal: 48,
                  vertical: 16,
                ),
              ),
              child: const Text('Zaloguj'),
            ),
            TextButton(
              onPressed: _onClickOpenRegister,
              style: TextButton.styleFrom(
                foregroundColor: widget.options.secondaryButtonColor,
              ),
              child: const Text('Nie masz konta? Zarejestruj sie'),
            ),
          ],
        ),
      ),
    );
  }
}