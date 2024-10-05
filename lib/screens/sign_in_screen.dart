import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:flutter/material.dart';
import '../constants/colors.dart'; // Adjust the path as needed
import '../constants/styles.dart';
import '../widgets/reused_elevated_button.dart';
import '../widgets/reused_textform_field.dart';
import 'login_screen.dart';
import 'package:intl_phone_field/intl_phone_field.dart'; // For the phone number field
import 'package:icons_plus/icons_plus.dart'; // Import the icons_plus package

class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height; // Get device height

    return Scaffold(
      backgroundColor: kSecondaryColor, // Use kSecondaryColor (white)
      body: SingleChildScrollView(
        // This will allow scrolling
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: height, // Set minimum height to match the screen size
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Sign in',
                  style: kPrimaryStyle,
                ),
                20.kH,
                // Email TextFormField
                const ReusedTextFormField(
                  hintText: 'Email',
                  prefixIcon: Icons.email, // Email icon from icons_plus
                ),
                20.kH,
                // Password TextFormField
                const ReusedTextFormField(
                  hintText: 'Password',
                  prefixIcon: LineAwesome.user_lock_solid, // Password lock icon
                  obscureText: true, // Password field should hide text
                ),
                20.kH,
                // Phone Number Field with Country Code
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    // Set the default enabled border
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: kDeepOrange), // Border color when enabled
                      borderRadius: BorderRadius.circular(30),
                    ),
                    // Set the border color when focused
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                          color: kDeepOrange,
                          width: 2), // Border color when focused
                      borderRadius: BorderRadius.circular(30),
                    ),
                    // Set the border color when there's an error
                    errorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Colors.red,
                          width: 2), // Border color when there's an error
                      borderRadius: BorderRadius.circular(30),
                    ),
                    // Set the border for focused error
                    focusedErrorBorder: OutlineInputBorder(
                      borderSide: const BorderSide(
                          color: Colors.red,
                          width:
                              2), // Border color when focused and there's an error
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  initialCountryCode: 'SA', // Default country code
                  onChanged: (phone) {
                    print(phone.completeNumber); // Handle phone number input
                  },
                ),
                10.kH,
                // Send OTP Button
                CustomButton(
                  text: 'Sign Up', // Phone icon for the button
                  onPressed: () {
                    // Your OTP logic here
                  },
                ),
                20.kH,
                // Already have an account? Login Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("Already have an account? "),
                    GestureDetector(
                      onTap: () {
                        // Navigate to the login screen
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
