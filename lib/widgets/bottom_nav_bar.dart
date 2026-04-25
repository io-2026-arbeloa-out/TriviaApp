import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';
import 'package:triviaapp/models/ui_options.dart';

class AppBottomNavigationBar extends StatelessWidget {
  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.options,
  });

  final int currentIndex;
  final UIOptions options;

  /// currentIndex:
  /// 0 - Quizy
  /// 1 - Main menu
  /// 2 - Profil

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        AppRoute.instance.goToQuizList(options);
      case 1:
        AppRoute.instance.goToMainMenu(options);
      case 2:
        AppRoute.instance.goToProfile(options);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: _onItemTapped,
      backgroundColor: options.textColor,
      selectedItemColor: options.mainColor,
      unselectedItemColor: options.secondaryColor,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'Quizy'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Menu'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }
}