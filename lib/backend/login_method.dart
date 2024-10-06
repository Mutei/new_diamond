import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/main_screen.dart';
import '../utils/global_methods.dart';

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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainScreen()),
        (Route<dynamic> route) => false,
      );
    } on FirebaseAuthException catch (e) {
      // Handle specific FirebaseAuth errors
      if (e.code == 'user-not-found') {
        showErrorDialog(context, "No user found for that email.");
      } else if (e.code == 'wrong-password') {
        showErrorDialog(context, "Wrong password provided for that email.");
      } else if (e.code == 'invalid-email') {
        showErrorDialog(context, "The email address is not valid.");
      } else {
        showErrorDialog(
            context, e.message ?? "Login failed. Please try again.");
      }
    } catch (e) {
      // Show a generic error message for other exceptions
      showErrorDialog(
          context, "An unexpected error occurred. Please try again.");
    }
  }
}
