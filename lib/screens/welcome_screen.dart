import 'package:diamond_host_admin/localization/language_constants.dart';
import 'package:flutter/material.dart';

import '../widgets/welcome_screen_widgets.dart'; // Import the new file

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  _WelcomeScreenState createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              children: [
                buildPage(
                  image: 'assets/images/p1.png',
                  text: getTranslated(
                    context,
                    "Book a hotel, restaurant or cafe and experience our best services",
                  ),
                  context: context,
                ),
                buildPage(
                  image: 'assets/images/p2.png',
                  text: getTranslated(
                    context,
                    "You can also book a table in a restaurant or adequate for you",
                  ),
                  context: context,
                ),
                buildPage(
                  image: 'assets/images/p3.png',
                  text: getTranslated(
                    context,
                    "Enjoy the finest services with Premium and Premium Plus",
                  ),
                  isLastPage: true,
                  context: context,
                ),
              ],
            ),
          ),
          buildIndicator(_currentIndex, 3),
        ],
      ),
    );
  }
}
