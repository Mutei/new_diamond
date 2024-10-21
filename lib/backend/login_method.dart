import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../screens/main_screen.dart';
import '../utils/global_methods.dart';

class LoginMethod {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();

  // Method to handle email login
  void loginWithEmail({
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

      // Fetch the user ID (UID)
      String uid = userCredential.user!.uid;

      // Fetch TypeUser from Firebase Realtime Database
      DatabaseReference typeUserRef =
          _databaseRef.child('App/User/$uid/TypeUser');
      DataSnapshot snapshot = await typeUserRef.get();

      // Check if TypeUser exists and if it's '1'
      if (snapshot.exists && snapshot.value == '1') {
        // If TypeUser is '1', navigate to the MainScreen
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        // If TypeUser is not '1', sign the user out and show an alert dialog
        await _auth.signOut(); // Sign out the unauthorized user
        showLoginErrorDialog(context, "You are not allowed to log in.");
      }
    } on FirebaseAuthException catch (e) {
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
      showErrorDialog(
          context, "An unexpected error occurred. Please try again.");
    }
  }

  // Helper method to show an alert dialog
  void showAlertDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
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
