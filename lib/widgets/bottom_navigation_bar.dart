import 'package:diamond_host_admin/localization/language_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state_management/general_provider.dart';

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
    // Access the GeneralProvider to get the count of new booking statuses
    final provider = Provider.of<GeneralProvider>(context);

    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onItemTapped,
      selectedItemColor: Colors.deepPurple,
      unselectedItemColor: Colors.grey,
      items: [
        BottomNavigationBarItem(
          icon: const Icon(Icons.home),
          label: getTranslated(context, 'Main Screens'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.upgrade),
          label: getTranslated(context, 'Upgrade Account'),
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.book_online), // The booking status icon
              if (provider.approvalCount > 0) // Show badge only if count > 0
                Positioned(
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      provider.approvalCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: getTranslated(context, 'Booking Status'),
        ),
        BottomNavigationBarItem(
          icon: const Icon(Icons.post_add),
          label: getTranslated(context, 'All Posts'),
        ),
      ],
    );
  }
}
