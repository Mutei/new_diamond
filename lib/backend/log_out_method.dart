import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../screens/login_screen.dart';

class LogOutMethod {
  final _database = FirebaseDatabase.instance.ref();

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

      // Remove the Token from Firebase Realtime Database
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await _database.child('App/User/$userId/Token').remove();
      }

      // Sign out the user
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
