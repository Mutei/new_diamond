import 'package:diamond_host_admin/constants/styles.dart';
import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class SignInScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSecondaryColor, // Use kSecondaryColor (white)
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Sign in',
              style: kPrimaryStyle,
            ),
            20.kH,
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors
                      .deepOrange[300]!, // Darker border color for visibility
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Email or User Name',
                  prefixIcon: Icon(
                    Icons.email_outlined,
                    color: kSecondaryGradient,
                  ), // Darker icon color
                  hintStyle: TextStyle(
                    color: kTypeUserTextColor,
                  ), // Slightly darker hint text
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
            20.kH,
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: kSecondaryGradient, // Darker border for password field
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                obscureText: true,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Password',
                  prefixIcon: Icon(
                    Icons.lock_outline,
                    color: kSecondaryGradient,
                  ), // Darker icon color
                  suffixIcon: Icon(
                    Icons.visibility_outlined,
                    color: kTypeUserTextColor,
                  ),
                  hintStyle: TextStyle(color: kTypeUserTextColor),
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                ),
              ),
            ),
            20.kH,
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: kPrimaryGradient, // Use the gradient from colors.dart
              ),
              child: TextButton(
                onPressed: () {},
                child: const Text(
                  'Sign in',
                  style: TextStyle(
                    color: Colors.white, // White text for better contrast
                    fontSize: 18,
                  ),
                ),
              ),
            ),
            // Other widgets like "Or sign in with" buttons...
          ],
        ),
      ),
    );
  }
}
