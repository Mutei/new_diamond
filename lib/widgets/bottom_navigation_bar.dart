import 'package:diamond_host_admin/localization/language_constants.dart';
import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onItemTapped;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onItemTapped,
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onItemTapped,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: getTranslated(context, 'Main Screens'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.upgrade),
          label: getTranslated(context, 'Upgrade Account'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.book_online),
          label: getTranslated(context, 'Booking Status'),
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.post_add),
          label: getTranslated(context, 'All Posts'),
        ),
      ],
    );
  }
}
