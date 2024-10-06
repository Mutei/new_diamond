import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:diamond_host_admin/widgets/reused_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:intl_phone_number_input/intl_phone_number_input.dart';

import '../constants/styles.dart';
import '../widgets/reused_phone_number_widget.dart';
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
  final _formKey = GlobalKey<FormState>(); // Form key to manage the form state
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        // Added this to make the screen scrollable
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
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

                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
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
                          ReusedTextFormField(
                            controller: _emailController,
                            hintText: 'Email',
                            prefixIcon: Icons.email,
                            validator: (value) {
                              if (_currentIndex == 0) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your email';
                                }
                                // Validate email format
                                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+')
                                    .hasMatch(value)) {
                                  return 'Please enter a valid email address';
                                }
                              }
                              return null;
                            },
                          ),
                          20.kH,
                          ReusedTextFormField(
                            controller: _passwordController,
                            hintText: 'Password',
                            prefixIcon: LineAwesome.user_lock_solid,
                            obscureText: true,
                            validator: (value) {
                              if (_currentIndex == 0) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your password';
                                }
                                // Optional: Add a length constraint if needed
                              }
                              return null;
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
                            text: 'Login',
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                // Proceed with email/password login logic
                                print('Logging in with email and password');
                              }
                            },
                          ),
                        ],
                      ),

                      // Phone Number Form
                      Column(
                        children: [
                          ReusedPhoneNumberField(
                            onPhoneNumberChanged: (phone) {
                              setState(() {
                                _phoneNumber = phone;
                              });
                            },
                            validator: (phone) {
                              if (_currentIndex == 1) {
                                if (phone == null || phone.number.isEmpty) {
                                  return 'Please enter a valid phone number';
                                }
                              }
                              return null;
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
                              if (_formKey.currentState!.validate()) {
                                // Proceed with phone number login logic
                                print('Logging in with phone number');
                              }
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
      ),
    );
  }
}
