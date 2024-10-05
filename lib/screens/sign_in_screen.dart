import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart'; // Adjust the path as needed
import '../constants/styles.dart';
import '../widgets/reused_elevated_button.dart';
import '../widgets/reused_textform_field.dart';
import 'login_screen.dart';

import 'package:icons_plus/icons_plus.dart'; // Import the icons_plus package

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

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
            const ReusedTextFormField(
                hintText: 'Email or User Name',
                prefixIcon: IonIcons.person_circle),
            20.kH,
            const ReusedTextFormField(
              hintText: 'Password',
              prefixIcon:
                  LineAwesome.user_lock_solid, // Using an icon from icons_plus
              obscureText: true, // Password field
            ),
            20.kH,
            CustomButton(
              text: 'Sign in',
              onPressed: () {
                // Your sign in logic
              },
            ),
            20.kH,
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Already have an account? "),
                GestureDetector(
                  onTap: () {
                    // Navigate to the login screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => LoginScreen()),
                    );
                  },
                  child: const Text(
                    "Login",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
