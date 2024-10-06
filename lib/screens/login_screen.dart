import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:diamond_host_admin/widgets/reused_elevated_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:diamond_host_admin/widgets/reused_appbar.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../constants/styles.dart';
import '../widgets/reused_textform_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool rememberMe = false;
  String initialCountry = 'SA';
  PhoneNumber number = PhoneNumber(isoCode: 'SA');
  PageController _pageController = PageController(initialPage: 0);
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // Added this to make the screen scrollable
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Tabs for "Email & Password" and "Phone Number"
              40.kH, // Added space for status bar
              Text(
                "Login",
                style: kPrimaryStyle,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 2.0,
                              color: _currentIndex == 0
                                  ? kOrange
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                        child: Text(
                          'Email & Password',
                          textAlign: TextAlign.center,
                          style: kSecondaryStyle,
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _pageController.animateToPage(
                          1,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              width: 2.0,
                              color: _currentIndex == 1
                                  ? kOrange
                                  : Colors.transparent,
                            ),
                          ),
                        ),
                        child: Text(
                          'Phone Number',
                          textAlign: TextAlign.center,
                          style: kSecondaryStyle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              20.kH,

              // PageView to allow swiping between the forms
              SizedBox(
                height: MediaQuery.of(context).size.height *
                    0.6, // Adjust height to avoid overflow
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  children: [
                    // Email & Password Form
                    Column(
                      children: [
                        const ReusedTextFormField(
                          hintText: 'Email',
                          prefixIcon: Icons.email, // Email icon from icons_plus
                        ),
                        20.kH,
                        const ReusedTextFormField(
                          hintText: 'Password',
                          prefixIcon:
                              LineAwesome.user_lock_solid, // Password lock icon
                          obscureText: true, // Password field should hide text
                        ),
                        10.kH,
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  rememberMe = value!;
                                });
                              },
                            ),
                            const Text("Remember Me"),
                          ],
                        ),
                        20.kH,
                        CustomButton(
                          text: 'Login',
                          onPressed: () {
                            // Your sign in logic
                          },
                        ),
                      ],
                    ),

                    // Phone Number Form
                    Column(
                      children: [
                        IntlPhoneField(
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            // Set the default enabled border
                            enabledBorder: OutlineInputBorder(
                              borderSide: BorderSide(
                                  color:
                                      kDeepOrange), // Border color when enabled
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
                                  width:
                                      2), // Border color when there's an error
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
                            print(phone
                                .completeNumber); // Handle phone number input
                          },
                        ),
                        10.kH,
                        Row(
                          children: [
                            Checkbox(
                              value: rememberMe,
                              onChanged: (value) {
                                setState(() {
                                  rememberMe = value!;
                                });
                              },
                            ),
                            const Text("Remember Me"),
                          ],
                        ),
                        20.kH,
                        CustomButton(
                          text: 'Login through phone number',
                          onPressed: () {
                            // Your sign in logic
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Are you new here? "),
                  GestureDetector(
                    onTap: () {
                      // Navigate to Sign Up Screen
                    },
                    child: const Text(
                      "Sign Up",
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
    );
  }
}
