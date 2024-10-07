import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:diamond_host_admin/localization/language_constants.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../backend/authentication_methods.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../state_management/general_provider.dart';
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
          // Language change button
          IconButton(
            icon: Icon(Icons.language, color: kPurpleColor),
            onPressed: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return const LanguageDialogWidget();
                },
              );
            },
          ),
          // Dark/Light mode toggle button
          Consumer<GeneralProvider>(
            builder: (context, generalProvider, child) {
              return IconButton(
                icon: Icon(
                  generalProvider.isDarkMode
                      ? Icons.dark_mode
                      : Icons.light_mode,
                  color: kPurpleColor,
                ),
                onPressed: () {
                  generalProvider.toggleTheme(); // Toggle theme
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
                  Text(getTranslated(context, 'Sign in'), style: kPrimaryStyle),
                  20.kH,
                  ReusedTextFormField(
                    controller: _emailController,
                    hintText: getTranslated(context, 'Email'),
                    prefixIcon: Icons.email,
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return getTranslated(
                            context, 'Please enter your email');
                      }
                      return null;
                    },
                  ),
                  20.kH,
                  ReusedTextFormField(
                    controller: _passwordController,
                    hintText: getTranslated(context, 'Password'),
                    prefixIcon: LineAwesome.user_lock_solid,
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return getTranslated(
                            context, 'Please enter your password');
                      }
                      if (!RegExp(r'^(?=.*?[A-Z])(?=.*?[!@#\$&*~]).{8,}$')
                          .hasMatch(value)) {
                        return getTranslated(context, 'Password Description');
                      }
                      return null;
                    },
                  ),
                  20.kH,
                  ReusedPhoneNumberField(
                    onPhoneNumberChanged: (phone) {
                      setState(() {
                        _phoneNumber = phone;
                      });
                    },
                    validator: (phone) {
                      if (phone == null || phone.number.isEmpty) {
                        return getTranslated(
                            context, 'Please enter a valid phone number');
                      }
                      return null;
                    },
                  ),
                  10.kH,
                  CheckboxListTile(
                    title: Text(getTranslated(
                        context, 'I accept the terms and conditions')),
                    value: _acceptedTerms,
                    onChanged: (value) {
                      setState(() {
                        _acceptedTerms = value!;
                      });
                    },
                  ),
                  CustomButton(
                    text: getTranslated(context, 'Sign in'),
                    onPressed: () async {
                      // Hide the keyboard
                      FocusScope.of(context).unfocus();

                      if (_formKey.currentState!.validate()) {
                        if (!_acceptedTerms) {
                          // Show error if terms are not accepted
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(getTranslated(context,
                                  'Please accept the terms and conditions')),
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
                  20.kH,
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        getTranslated(context, "Already have an account? "),
                        style: Theme.of(context)
                            .textTheme
                            .bodyLarge, // Replace bodyText1 with bodyLarge
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const LoginScreen()),
                          );
                        },
                        child: Text(
                          getTranslated(context, "Login"),
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: Colors
                                        .blue, // Keeping the blue color for this specific text
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
