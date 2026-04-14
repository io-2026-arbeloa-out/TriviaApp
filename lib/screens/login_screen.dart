import 'package:flutter/material.dart';
import 'package:triviaapp/models/ui_options.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final UIOptions options = UIOptions();

  @override
  Widget build(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();

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
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.quiz,
                    size: 80,
                    color: options.textColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Zaloguj się',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      color: options.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildTextField(
                    context,
                    controller: emailController,
                    label: 'Email',
                    obscure: false,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    context,
                    controller: passwordController,
                    label: 'Hasło',
                    obscure: true,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: options.mainButtonColor,
                        foregroundColor: options.textColor,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                          side: BorderSide(color: Colors.black, width: 2),
                        ),
                      ),
                      onPressed: () {
                        // TODO: logowanie
                      },
                      child: const Text(
                        'Zaloguj',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      // TODO: otwórz ekran rejestracji
                    },
                    child: Text(
                      'Nie masz konta? Zarejestruj się',
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

  Widget _buildTextField(
      BuildContext context, {
        required TextEditingController controller,
        required String label,
        required bool obscure,
      }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: TextStyle(color: options.textColor),
      cursorColor: options.textColor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: options.textColor.withOpacity(0.8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: options.textColor.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: options.textColor,
            width: 2,
          ),
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.1),
      ),
    );
  }
}