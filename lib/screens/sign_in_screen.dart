import 'package:flutter/material.dart';
import '../backend/authentication_methods.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../widgets/language_translator_widget.dart';
import '../widgets/reused_elevated_button.dart';
import '../widgets/reused_phone_number_widget.dart';
import '../widgets/reused_textform_field.dart';
import 'login_screen.dart';
import 'package:icons_plus/icons_plus.dart'; // Import the icons_plus package

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _phoneNumber;
  bool _acceptedTerms = false; // Track if terms are accepted

  final AuthenticationMethods _authMethods = AuthenticationMethods();

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          // Icon button for changing language
          IconButton(
            icon: Icon(Icons.language, color: kOrangeColor),
            onPressed: () {
              // Show the language dialog as a custom widget
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const LanguageDialogWidget();
                },
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sign in', style: kPrimaryStyle),
                  const SizedBox(height: 20),
                  ReusedTextFormField(
                    controller: _emailController,
                    hintText: 'Email',
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ReusedTextFormField(
                    controller: _passwordController,
                    hintText: 'Password',
                    prefixIcon: LineAwesome.user_lock_solid,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (!RegExp(r'^(?=.*?[A-Z])(?=.*?[!@#\$&*~]).{8,}$')
                          .hasMatch(value)) {
                        return 'Password must be at least 8 characters, 1 special char, 1 uppercase';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  ReusedPhoneNumberField(
                    onPhoneNumberChanged: (phone) {
                      setState(() {
                        _phoneNumber = phone;
                      });
                    },
                    validator: (phone) {
                      if (phone == null || phone.number.isEmpty) {
                        return 'Please enter a valid phone number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  CheckboxListTile(
                    title: const Text('I accept the terms and conditions'),
                    value: _acceptedTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptedTerms = value!;
                      });
                    },
                  ),
                  CustomButton(
                    text: 'Sign Up',
                    onPressed: () async {
                      // Hide the keyboard
                      FocusScope.of(context).unfocus();

                      if (_formKey.currentState!.validate()) {
                        if (!_acceptedTerms) {
                          // Show error if terms are not accepted
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Please accept the terms and conditions'),
                            ),
                          );
                          return;
                        }

                        // Call sign-up method
                        try {
                          await _authMethods.signUpWithEmailPhone(
                            email: _emailController.text.trim(),
                            password: _passwordController.text.trim(),
                            phone: _phoneNumber!, // Make sure this is not null
                            acceptedTerms: _acceptedTerms,
                            context: context, // Pass the context here
                          );
                          print('OTP sent for verification');
                        } catch (e) {
                          print('Sign-up failed: $e');
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Already have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
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
      ),
    );
  }
}
