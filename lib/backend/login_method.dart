import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/main_screen.dart'; // Import your MainScreen widget

class LoginMethod {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Method to handle email login
  Future<void> loginWithEmail({
    required String email,
    required String password,
    required BuildContext context,
  }) async {
    try {
      // Sign in the user with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // If login is successful, navigate to the MainScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MainScreen()),
      );
    } on FirebaseAuthException catch (e) {
      // Handle specific FirebaseAuth errors
      if (e.code == 'user-not-found') {
        _showErrorDialog(context, "No user found for that email.");
      } else if (e.code == 'wrong-password') {
        _showErrorDialog(context, "Wrong password provided for that email.");
      } else if (e.code == 'invalid-email') {
        _showErrorDialog(context, "The email address is not valid.");
      } else {
        _showErrorDialog(
            context, e.message ?? "Login failed. Please try again.");
      }
    } catch (e) {
      // Show a generic error message for other exceptions
      _showErrorDialog(
          context, "An unexpected error occurred. Please try again.");
    }
  }

  // Method to display an error alert dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Login Failed"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }
}
