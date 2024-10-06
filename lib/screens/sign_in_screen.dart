import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:flutter/material.dart';
import '../constants/styles.dart';

import '../constants/colors.dart';
import '../widgets/reused_elevated_button.dart';
import '../widgets/reused_phone_number_widget.dart';
import '../widgets/reused_textform_field.dart';
import 'login_screen.dart';
import 'package:icons_plus/icons_plus.dart'; // Import the icons_plus package

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: kSecondaryColor, // Use kSecondaryColor (white)
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Sign in', style: kPrimaryStyle),
                20.kH,
                const ReusedTextFormField(
                  hintText: 'Email',
                  prefixIcon: Icons.email,
                ),
                20.kH,
                const ReusedTextFormField(
                  hintText: 'Password',
                  prefixIcon: LineAwesome.user_lock_solid,
                  obscureText: true,
                ),
                20.kH,
                // Use the custom phone number field
                ReusedPhoneNumberField(
                  onPhoneNumberChanged: (phone) {
                    print('Phone number entered: $phone');
                  },
                ),
                10.kH,
                CustomButton(
                  text: 'Sign Up',
                  onPressed: () {
                    // Your OTP logic here
                  },
                ),
                20.kH,
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => LoginScreen()),
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
        ),
      ),
    );
  }
}
