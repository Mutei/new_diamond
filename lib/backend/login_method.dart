// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import '../screens/main_screen.dart';
// import '../utils/global_methods.dart';
//
// class LoginMethod {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
//
//   // Method to handle email login
//   void loginWithEmail({
//     required String email,
//     required String password,
//     required BuildContext context,
//   }) async {
//     try {
//       // Show the custom loading dialog while processing the login
//       showCustomLoadingDialog(context);
//
//       // Sign in the user with email and password
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//
//       // Fetch the user ID (UID)
//       String uid = userCredential.user!.uid;
//
//       // Fetch TypeUser from Firebase Realtime Database
//       DatabaseReference typeUserRef =
//           _databaseRef.child('App/User/$uid/TypeUser');
//       DataSnapshot snapshot = await typeUserRef.get();
//       String? token = await FirebaseMessaging.instance.getToken();
//       DatabaseReference userRef =
//           FirebaseDatabase.instance.ref("App/User/$uid");
//
//       // Dismiss the loading dialog after getting the result from Firebase
//       Navigator.of(context, rootNavigator: true).pop();
//
//       // Check if TypeUser exists and if it's '1'
//       if (snapshot.exists && snapshot.value == '1') {
//         // If TypeUser is '1', navigate to the MainScreen
//         if (token != null) {
//           await userRef.update({"Token": token});
//         }
//         Navigator.of(context).pushAndRemoveUntil(
//           MaterialPageRoute(builder: (context) => const MainScreen()),
//           (Route<dynamic> route) => false,
//         );
//       } else {
//         // If TypeUser is not '1', sign the user out and show an alert dialog
//         await _auth.signOut(); // Sign out the unauthorized user
//         showLoginErrorDialog(context, "You are not allowed to log in.");
//       }
//     } on FirebaseAuthException catch (e) {
//       // Dismiss the loading dialog in case of an error
//       Navigator.of(context, rootNavigator: true).pop();
//
//       // Handle Firebase authentication errors
//       if (e.code == 'user-not-found') {
//         showErrorDialog(context, "No user found for that email.");
//       } else if (e.code == 'wrong-password') {
//         showErrorDialog(context, "Wrong password provided for that email.");
//       } else if (e.code == 'invalid-email') {
//         showErrorDialog(context, "The email address is not valid.");
//       } else {
//         showErrorDialog(
//             context, e.message ?? "Login failed. Please try again.");
//       }
//     } catch (e) {
//       // Dismiss the loading dialog in case of an unexpected error
//       Navigator.of(context, rootNavigator: true).pop();
//
//       // Show a generic error message
//       showErrorDialog(
//           context, "An unexpected error occurred. Please try again.");
//     }
//   }
//
//   // Helper method to show an alert dialog
//   void showAlertDialog(BuildContext context, String title, String message) {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           title: Text(title),
//           content: Text(message),
//           actions: <Widget>[
//             TextButton(
//               onPressed: () {
//                 Navigator.of(context).pop();
//               },
//               child: const Text("OK"),
//             ),
//           ],
//         );
//       },
//     );
//   }
// }
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../screens/main_screen.dart';
import '../screens/otp_login_screen.dart';
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
      // Show loading dialog
      showCustomLoadingDialog(context);

      // Sign in with email and password
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = userCredential.user!.uid;

      // Retrieve the token
      String? token = await FirebaseMessaging.instance.getToken();
      print("Retrieved token: $token");

      DatabaseReference userRef =
          FirebaseDatabase.instance.ref("App/User/$uid");
      DatabaseReference typeUserRef =
          _databaseRef.child('App/User/$uid/TypeUser');
      DataSnapshot snapshot = await typeUserRef.get();

      Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog

      if (snapshot.value == '1') {
        if (token != null) {
          // Update token in the database
          await userRef.update({"Token": token});

          // Read back the token from the database to confirm
          DataSnapshot tokenSnapshot = await userRef.child("Token").get();
          print("Token saved in DB: ${tokenSnapshot.value}");
        }
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (Route<dynamic> route) => false,
        );
      } else {
        await _auth.signOut();
        showLoginErrorDialog(context, "You are not allowed to log in.");
      }
    } on FirebaseAuthException catch (e) {
      Navigator.of(context, rootNavigator: true).pop();

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
      Navigator.of(context, rootNavigator: true).pop();
      showErrorDialog(
          context, "An unexpected error occurred. Please try again.");
    }
  }

  void loginWithPhone({
    required String phoneNumber,
    required BuildContext context,
  }) async {
    try {
      showCustomLoadingDialog(context);

      DatabaseReference userRef = _databaseRef.child('App/User');
      DataSnapshot usersSnapshot = await userRef.get();
      String? uid;

      for (var user in usersSnapshot.children) {
        final phone = user.child("PhoneNumber").value as String?;
        if (phone == phoneNumber) {
          uid = user.key;
          break;
        }
      }

      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading

      if (uid == null) {
        showErrorDialog(context, "User not found with this phone number.");
        return;
      }

      DatabaseReference typeUserRef = userRef.child('$uid/TypeUser');
      DataSnapshot snapshot = await typeUserRef.get();

      // Retrieve the token
      String? token = await FirebaseMessaging.instance.getToken();
      print("Retrieved token (phone login): $token");

      DatabaseReference userRefs =
          FirebaseDatabase.instance.ref("App/User/$uid");

      if (snapshot.value == '2') {
        await _auth.verifyPhoneNumber(
          phoneNumber: phoneNumber,
          verificationCompleted: (PhoneAuthCredential credential) async {
            // Auto-retrieval or instant verification
            if (token != null) {
              await userRefs.update({"Token": token});

              // Read back token from DB for verification
              DataSnapshot tokenSnapshot = await userRefs.child("Token").get();
              print("Token saved in DB (phone login): ${tokenSnapshot.value}");
            }
            await _auth.signInWithCredential(credential);
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const MainScreen()),
              (Route<dynamic> route) => false,
            );
          },
          verificationFailed: (FirebaseAuthException e) {
            showErrorDialog(context, e.message ?? "Verification failed.");
          },
          codeSent: (String verificationId, int? resendToken) {
            Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => OTPLoginScreen(
                phoneNumber: phoneNumber,
                verificationId: verificationId,
              ),
            ));
          },
          codeAutoRetrievalTimeout: (String verificationId) {
            // Optionally handle timeout
          },
        );
      } else {
        showLoginErrorDialog(context, "You are not allowed to log in.");
      }
    } catch (e) {
      Navigator.of(context, rootNavigator: true).pop(); // Dismiss loading
      showErrorDialog(context, "An error occurred. Please try again.");
    }
  }

  Future<void> linkWithEmailAndPhone({
    required String email,
    required String phoneNumber,
    required String verificationId,
    required String smsCode,
    required BuildContext context,
  }) async {
    try {
      // Authenticate the phone credential using OTP
      PhoneAuthCredential phoneCredential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      // Sign in with the phone number first
      UserCredential phoneUserCredential =
          await _auth.signInWithCredential(phoneCredential);

      // Now, link email credential to the phone-authenticated user
      User? user = phoneUserCredential.user;
      AuthCredential emailCredential = EmailAuthProvider.credential(
        email: email,
        password: 'some_password', // You can also pass the password here
      );
      await user!.linkWithCredential(emailCredential);

      // After linking, navigate to the main screen
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (Route<dynamic> route) => false,
      );
    } catch (e) {
      showErrorDialog(context, 'Failed to link email with phone');
    }
  }

  // Helper function to check TypeUser
  void _checkTypeUser(String? uid, BuildContext context) async {
    if (uid == null) {
      showErrorDialog(context, "Unable to verify user ID.");
      return;
    }

    showCustomLoadingDialog(context);
    DatabaseReference typeUserRef =
        _databaseRef.child('App/User/$uid/TypeUser');
    DataSnapshot snapshot = await typeUserRef.get();

    Navigator.of(context, rootNavigator: true).pop(); // Close loading dialog

    if (snapshot.value == '2') {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const MainScreen()),
        (Route<dynamic> route) => false,
      );
    } else {
      await _auth.signOut();
      showLoginErrorDialog(context, "You are not allowed to log in.");
    }
  }
}
