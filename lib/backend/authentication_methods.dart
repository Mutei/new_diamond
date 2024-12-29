// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_database/firebase_database.dart';
// import 'package:flutter/material.dart';
// import 'package:intl/intl.dart';
//
// import '../screens/main_screen.dart';
//
// class AuthenticationMethods {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final DatabaseReference _db = FirebaseDatabase.instance.ref();
//
//   Future<void> signUpWithEmailPhone({
//     required String email,
//     required String password,
//     required String phone,
//     required bool acceptedTerms,
//     required BuildContext context, // Add context as a required parameter
//   }) async {
//     try {
//       // Password validation
//       if (!validatePassword(password)) {
//         throw Exception(
//             "Password must be at least 8 characters long, contain 1 special character, and 1 capital letter");
//       }
//
//       // Create a new user with email and password
//       UserCredential userCredential =
//           await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//
//       // Send OTP to phone number
//       await sendOTP(phone);
//
//       // Save user info in Firebase Realtime Database after OTP confirmation
//       String userId = userCredential.user!.uid;
//       String registrationDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
//       await _db.child('App/User/$userId').set({
//         'Email': email,
//         'PhoneNumber': phone,
//         'AcceptedTermsAndConditions': acceptedTerms,
//         'TypeUser': '1', // Assuming '1' is for a regular user
//         'DateOfRegistration': registrationDate,
//       });
//
//       // Navigate to MainScreen after successful signup
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(builder: (context) => const MainScreen()),
//       );
//     } catch (e) {
//       throw Exception('Sign up failed: ${e.toString()}');
//     }
//   }
//
//   // Validate the password strength
//   bool validatePassword(String password) {
//     final RegExp passwordRegExp = RegExp(
//       r'^(?=.*?[A-Z])(?=.*?[!@#\$&*~]).{8,}$',
//     );
//     return passwordRegExp.hasMatch(password);
//   }
//
//   // Mock method for sending OTP, integrate your actual logic
//   Future<void> sendOTP(String phoneNumber) async {
//     // Integrate OTP sending logic here using Firebase Authentication
//     print('OTP sent to $phoneNumber');
//   }
// }
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../screens/main_screen.dart';
import '../screens/fill_info_screen.dart';
import '../screens/otp_screen.dart';

class AuthenticationMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> signUpWithEmailPhone({
    required String email,
    required String password,
    required String phone,
    required bool acceptedTerms,
    required String agentCode, // New parameter for Agent Code
    required BuildContext context,
  }) async {
    try {
      if (!validatePassword(password)) {
        throw Exception(
            "Password must be at least 8 characters long, contain 1 special character, and 1 capital letter");
      }
      await sendOTP(phone, context, email, password, acceptedTerms,
          agentCode); // Pass Agent Code
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  Future<void> authenticateWithPhoneAndEmail({
    required String email,
    required String password,
    required String phone,
    required String verificationId,
    required String smsCode,
    required bool acceptedTerms,
    required String agentCode, // New parameter for Agent Code
    required BuildContext context,
  }) async {
    try {
      PhoneAuthCredential phoneCredential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      UserCredential phoneUserCredential =
          await _auth.signInWithCredential(phoneCredential);
      AuthCredential emailCredential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );

      await phoneUserCredential.user!.linkWithCredential(emailCredential);
      final userId = phoneUserCredential.user?.uid;

      if (userId == null) {
        throw Exception("User ID is null after linking credentials.");
      }

      await _saveUserData(
        email: email,
        password: password,
        phone: phone,
        userId: userId,
        acceptedTerms: acceptedTerms,
        agentCode: agentCode,
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const FillInfoScreen()),
      );
    } catch (e) {
      throw Exception('Phone and Email authentication failed: ${e.toString()}');
    }
  }

  Future<void> sendOTP(
    String phoneNumber,
    BuildContext context,
    String email,
    String password,
    bool acceptedTerms,
    String agentCode, // New parameter for Agent Code
  ) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) async {
        await authenticateWithPhoneAndEmail(
          email: email,
          password: password,
          phone: phoneNumber,
          verificationId: '',
          smsCode: '',
          acceptedTerms: acceptedTerms,
          agentCode: agentCode, // Pass Agent Code
          context: context,
        );
      },
      verificationFailed: (FirebaseAuthException e) {
        throw Exception('Phone verification failed: ${e.message}');
      },
      codeSent: (String verificationId, int? resendToken) async {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OTPScreen(
              verificationId: verificationId,
              phoneNumber: phoneNumber,
              email: email,
              password: password,
              acceptedTerms: acceptedTerms,
              agentCode: agentCode, // Pass Agent Code
            ),
          ),
        );
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print("Timeout");
      },
      timeout: const Duration(seconds: 120),
    );
  }

  Future<void> _saveUserData({
    required String email,
    required String password,
    required String phone,
    required String userId,
    required bool acceptedTerms,
    required String agentCode, // New parameter for Agent Code
  }) async {
    try {
      String registrationDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
      String? token = await FirebaseMessaging.instance.getToken();
      await _db.child('App/User/$userId').set({
        'Email': email,
        'Password': password,
        'PhoneNumber': phone,
        'AcceptedTermsAndConditions': acceptedTerms,
        'AgentCode':
            agentCode.isEmpty ? null : agentCode, // Save Agent Code if provided
        'TypeUser': '1',
        'DateOfRegistration': registrationDate,
        'TypeAccount': '1',
        'Token': token,
        'IsVerified': true,
      });
    } catch (error) {
      print("Error saving data to Firebase: $error");
    }
  }

  bool validatePassword(String password) {
    final RegExp passwordRegExp =
        RegExp(r'^(?=.*?[A-Z])(?=.*?[!@#\$&*~]).{8,}$');
    return passwordRegExp.hasMatch(password);
  }
}
