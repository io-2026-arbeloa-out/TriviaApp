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
        _authService = authService ??
            AuthRegisterService(
              authRepository: FirebaseAuthRepository(),
              profileRepository: FirebaseProfileRepository(),
            );

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  IRegisterAuthService get authService => widget._authService;
  UIOptions get options => widget._options;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;
  String? _errorMessage;

  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(_fade);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Widget _animated({required Widget child}) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: child,
      ),
    );
  }

  // ── Functionality ──────────────────────────────────────────────────────────

  Future<void> _onClickRegister() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final username = _usernameController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty ||
        username.isEmpty) {
      _showMessage('Wypelnij wszystkie pola.');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Hasla nie sa takie same.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await authService.register(email, password, username);
      if (!mounted) return;
      AppRoute.instance.goToMainMenu(options);
    } on FirebaseAuthException catch (e) {
      _showMessage(_mapFirebaseError(e.code));
    } catch (_) {
      _showMessage('Wystapil nieoczekiwany blad.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onClickClose() => AppRoute.instance.goBack();

  void _showMessage(String message) =>
      setState(() => _errorMessage = message);

  String _mapFirebaseError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Ten adres email jest już zajęty.';
      case 'invalid-display-name':
        return 'Nieprawidłowa nazwa użytkownika';
      case 'invalid-password':
        return 'Hasło jest za słabe (min. 6 znaków).';
      case 'invalid-email':
        return 'Nieprawidłowy adres email.';
      default:
        return 'Błąd rejestracji: $code';
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
            colors: [
              options.mainButtonColor.withOpacity(0.7),
              options.secondaryColor.withOpacity(0.7),
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: [
                _buildHeader(),
                _animated(child: _buildErrorBanner()),
                Expanded(child: _animated(child: _buildForm())),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    options.mainButtonColor.withOpacity(0.85),
                    options.secondaryColor,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(48),
                  bottomRight: Radius.circular(48),
                ),
              ),
            ),
          ),

          Positioned(
            top: 40,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: options.textColor),
                onPressed: _onClickClose,
              ),
            ),
          ),

          Positioned(
            left: -24,
            bottom: 20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: options.textColor.withOpacity(0.07),
              ),
            ),
          ),

          Positioned(
            right: 30,
            top: 48,
            child: Icon(
              Icons.person_add,
              size: 72,
              color: options.textColor.withOpacity(0.2),
            ),
          ),

          Positioned(
            bottom: 44,
            left: 0,
            right: 0,
            child: Text(
              'Rejestracja',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: options.textColor,
                fontSize: 36,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: _errorMessage == null
          ? const SizedBox(width: double.infinity)
          : Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(28, 20, 28, 0),
        padding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade800.withOpacity(0.85),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline,
                color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            GestureDetector(
              onTap: () => setState(() => _errorMessage = null),
              child: const Icon(Icons.close,
                  color: Colors.white, size: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    final inputBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:
      BorderSide(color: options.mainButtonColor.withOpacity(0.4)),
    );
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide:
      BorderSide(color: options.mainButtonColor, width: 2),
    );
    final labelStyle =
    TextStyle(color: options.textColor.withOpacity(0.7));
    final inputStyle = TextStyle(color: options.textColor);

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: options.secondaryColor.withOpacity(0.6),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: options.mainButtonColor.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _usernameController,
                  style: inputStyle,
                  decoration: InputDecoration(
                    labelText: 'Nazwa użytkownika',
                    labelStyle: labelStyle,
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: focusedBorder,
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _emailController,
                  style: inputStyle,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: labelStyle,
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: focusedBorder,
                    filled: true,
                    fillColor: Colors.transparent,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _passwordController,
                  obscureText: !_passwordVisible,
                  style: inputStyle,
                  decoration: InputDecoration(
                    labelText: 'Hasło',
                    labelStyle: labelStyle,
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: focusedBorder,
                    filled: true,
                    fillColor: Colors.transparent,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _passwordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: options.textColor.withOpacity(0.6),
                      ),
                      onPressed: () => setState(() =>
                      _passwordVisible = !_passwordVisible),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: !_confirmPasswordVisible,
                  style: inputStyle,
                  decoration: InputDecoration(
                    labelText: 'Potwierdź hasło',
                    labelStyle: labelStyle,
                    border: inputBorder,
                    enabledBorder: inputBorder,
                    focusedBorder: focusedBorder,
                    filled: true,
                    fillColor: Colors.transparent,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _confirmPasswordVisible
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: options.textColor.withOpacity(0.6),
                      ),
                      onPressed: () => setState(() =>
                      _confirmPasswordVisible =
                      !_confirmPasswordVisible),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: _isLoading
                ? Center(
                child: CircularProgressIndicator(
                    color: options.mainButtonColor))
                : DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: LinearGradient(
                  colors: [
                    options.mainButtonColor,
                    options.mainButtonColor.withOpacity(0.6),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: options.mainButtonColor.withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _onClickRegister,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: options.textColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Zarejestruj',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}