import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:diamond_host_admin/backend/authentication_methods.dart';
import 'package:diamond_host_admin/screens/personal_info_screen.dart';
import '../utils/failure_dialogue.dart';

class OTPScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final String email;
  final String password;
  final bool acceptedTerms;
  final String agentCode; // New parameter for Agent Code

  OTPScreen({
    Key? key,
    required this.verificationId,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.acceptedTerms,
    required this.agentCode, // Add agent code here
  }) : super(key: key);

  @override
  _OTPScreenState createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _otpController = TextEditingController();
  final AuthenticationMethods _loginMethod = AuthenticationMethods();
  bool _isLoading = false;

  Future<void> _verifyOTP() async {
    bool isVerified = false;

    try {
      if (widget.verificationId.isEmpty || _otpController.text.trim().isEmpty) {
        throw Exception("Invalid OTP or Verification ID.");
      }

      await _loginMethod.authenticateWithPhoneAndEmail(
        email: widget.email,
        phone: widget.phoneNumber,
        verificationId: widget.verificationId,
        smsCode: _otpController.text.trim(),
        context: context,
        password: widget.password,
        acceptedTerms: widget.acceptedTerms,
        agentCode: widget.agentCode, // Pass agent code
      );

      isVerified = true;
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      showDialog(
        context: context,
        builder: (context) => FailureDialog(
          text: "OTP Verification Failed",
          text1: "You have entered an incorrect OTP code. Please try again.",
        ),
      );
    }

    if (isVerified) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PersonalInfoScreen(
            email: widget.email,
            phoneNumber: widget.phoneNumber,
            password: widget.password,
            typeUser: '1',
            typeAccount: '1',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OTP Verification'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Enter the OTP sent to ${widget.phoneNumber}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(
                labelText: 'OTP',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: () async {
                      if (_otpController.text.isNotEmpty) {
                        setState(() {
                          _isLoading = true;
                        });
                        await _verifyOTP();
                      }
                    },
                    child: const Text('Verify OTP'),
                  ),
          ],
        ),
      ),
    );
  }
}
