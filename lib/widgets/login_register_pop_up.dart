import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/models/ui_options.dart';

class LoginRegisterPopUp extends StatelessWidget {
  LoginRegisterPopUp({
    super.key,
    UIOptions? options,
    required this.onClose,
  }) : _options = options ?? UIOptions();

  final void Function() onClose;
  final UIOptions _options;
  UIOptions get options => _options;

  void _onLoginPressed() {
    AppRoute.instance.goToLogin(options);
  }

  void _onRegisterPressed() {
    AppRoute.instance.goToRegistration(options);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [options.secondaryColor, options.mainColor],
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 12, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Zaloguj się, aby zapisywać wyniki i rywalizować z innymi!',
                  style: TextStyle(
                    color: options.textColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              IconButton(
                onPressed: onClose,
                icon: const Icon(Icons.close, size: 20),
                color: options.textColor.withOpacity(0.6),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: 'Zamknij',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: options.mainButtonColor,
                    foregroundColor: options.textColor,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _onLoginPressed,
                  child: const Text('Zaloguj się'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: options.mainButtonColor,
                    foregroundColor: options.textColor,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _onRegisterPressed,
                  child: const Text('Zarejestruj się'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}