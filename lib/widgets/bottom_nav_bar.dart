import 'package:flutter/material.dart';
import 'package:triviaapp/app_route.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  /// currentIndex:
  /// 0 - Quizy
  /// 1 - Main menu
  /// 2 - Profil

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
  });

  void _onClickMainMenu() {
    AppRoute.instance.goToMainMenu();
  }

  void _onClickQuizes() {
    AppRoute.instance.goToQuizList();
  }

  void _onClickProfile() {
    AppRoute.instance.goToProfile();
  }

  void _onItemTapped(int index) {
    switch (index) {
      case 0:
        _onClickQuizes();
        break;
      case 1:
        _onClickMainMenu();
        break;
      case 2:
        _onClickProfile();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: _onItemTapped,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.quiz),
          label: 'Quizy',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Menu',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profil',
        ),
      ],
    );
  }
}