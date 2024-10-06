import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/login_screen.dart';

class LogOutMethod {
  Future<void> logOut(BuildContext context) async {
    try {
      // Show a loading indicator if needed
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return Center(child: CircularProgressIndicator());
        },
      );

      await FirebaseAuth.instance.signOut();

      // Close the loading indicator
      Navigator.of(context).pop();

      // Navigate to the Login Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreen(),
        ),
      );
    } catch (e) {
      // Handle logout error, close the loading dialog, and show error message
      Navigator.of(context).pop(); // Close the loading indicator if any error
      print('Error logging out: $e');
    }
  }
}
