import 'package:flutter/material.dart';
import '../widgets/bottom_navigation_bar.dart';
import 'all_posts_screen.dart';
import 'notification_screen.dart';
import 'upgrade_account_screen.dart';
import 'main_screen_content.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const MainScreenContent(),
    const UpgradeAccountScreen(),
    const NotificationScreen(),
    const AllPostsScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavBar(
        currentIndex: _selectedIndex,
        onItemTapped: _onItemTapped,
      ),
    );
  }
}
