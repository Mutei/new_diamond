// import 'package:flutter/material.dart';
// import '../backend/authentication_methods.dart';
//
// class OTPVerificationScreen extends StatefulWidget {
//   final String phone;
//
//   const OTPVerificationScreen({Key? key, required this.phone})
//       : super(key: key);
//
//   @override
//   _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
// }
//
// class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
//   final AuthenticationMethods _authMethods = AuthenticationMethods();
//   final TextEditingController _otpController = TextEditingController();
//   bool isLoading = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text('OTP Verification')),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Text('Enter the OTP sent to ${widget.phone}',
//                 style: TextStyle(fontSize: 18)),
//             TextField(
//               controller: _otpController,
//               decoration: InputDecoration(
//                 hintText: 'Enter OTP',
//               ),
//               keyboardType: TextInputType.number,
//             ),
//             const SizedBox(height: 20),
//             isLoading
//                 ? CircularProgressIndicator() // Change this with your preferred loading indicator
//                 : ElevatedButton(
//                     onPressed: () async {
//                       setState(() {
//                         isLoading = true;
//                       });
//
//                       try {
//                         await _authMethods.verifyOTP(_otpController.text);
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           const SnackBar(content: Text('OTP Verified!')),
//                         );
//                         Navigator.of(context)
//                             .pop(); // Close OTP screen on success
//                       } catch (e) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text(e.toString())),
//                         );
//                       } finally {
//                         setState(() {
//                           isLoading = false;
//                         });
//                       }
//                     },
//                     child: const Text('Verify OTP'),
//                   ),
//           ],
//         ),
//       ),
//     );
//   }
// }
