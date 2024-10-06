import 'package:diamond_host_admin/constants/styles.dart';
import 'package:diamond_host_admin/screens/sign_in_screen.dart';
import 'package:diamond_host_admin/widgets/reused_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/screens/login_screen.dart';

Widget buildPage({
  required String image,
  required String text,
  bool isLastPage = false,
  required BuildContext context,
}) {
  return Padding(
    padding: const EdgeInsets.all(16.0),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Expanded(
          child: Image.asset(image), // Replace with correct asset path
        ),
        const SizedBox(height: 20),
        Text(
          text,
          textAlign: TextAlign.center,
          style: kSecondaryStyle,
        ),
        const SizedBox(height: 20),
        if (isLastPage)
          CustomButton(
            text: 'Next', // Phone icon for the button
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => SignInScreen()),
              );
            },
          ),
      ],
    ),
  );
}

Widget buildIndicator(int currentIndex, int totalPages) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalPages, (index) {
        return Container(
          margin: const EdgeInsets.all(4.0),
          width: 10.0,
          height: 10.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: currentIndex == index ? Colors.orange : Colors.grey,
          ),
        );
      }),
    ),
  );
}
