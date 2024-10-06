import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:flutter/material.dart';
import '../constants/styles.dart';
import '../constants/colors.dart';
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
  final _formKey = GlobalKey<FormState>(); // Form key to manage the form state
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String? _phoneNumber;

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
            child: Form(
              key: _formKey, // Associate the form key with the Form widget
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sign in', style: kPrimaryStyle),
                  20.kH,
                  ReusedTextFormField(
                    controller: _emailController,
                    hintText: 'Email',
                    prefixIcon: Icons.email,
                    // Add email validation
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
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
                    // Add password validation
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      return null;
                    },
                  ),
                  20.kH,
                  // Use the custom phone number field with validation
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
                  10.kH,
                  CustomButton(
                    text: 'Sign Up',
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Proceed with sign-up logic
                        print('Form is valid and phone number is entered');
                        // Proceed with your further logic
                      }
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
      ),
    );
  }
}
