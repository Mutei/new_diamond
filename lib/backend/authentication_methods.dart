import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class AuthenticationMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  Future<void> signUpWithEmailPhone(
      String email, String password, String phone, bool acceptedTerms) async {
    try {
      // Password validation
      if (!validatePassword(password)) {
        throw Exception(
            "Password must be at least 8 characters long, contain 1 special character, and 1 capital letter");
      }

      // Create a new user with email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Send OTP to phone number
      await sendOTP(phone);

      // Save user info in Firebase Realtime Database after OTP confirmation
      String userId = userCredential.user!.uid;
      String registrationDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
      await _db.child('App/User/$userId').set({
        'Email': email,
        'PhoneNumber': phone,
        'AcceptedTermsAndConditions': acceptedTerms,
        'TypeUser': '1', // Assuming '1' is for a regular user
        'DateOfRegistration': registrationDate,
      });
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Validate the password strength
  bool validatePassword(String password) {
    final RegExp passwordRegExp = RegExp(
      r'^(?=.*?[A-Z])(?=.*?[!@#\$&*~]).{8,}$',
    );
    return passwordRegExp.hasMatch(password);
  }

  // Mock method for sending OTP, integrate your actual logic
  Future<void> sendOTP(String phoneNumber) async {
    // Integrate OTP sending logic here using Firebase Authentication
    print('OTP sent to $phoneNumber');
  }
}
