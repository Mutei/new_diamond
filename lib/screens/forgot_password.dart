import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:diamond_host_admin/localization/language_constants.dart';
import 'package:diamond_host_admin/widgets/reused_appbar.dart';
import 'package:diamond_host_admin/widgets/reused_elevated_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../widgets/text_form_field_stile.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool validateEmail = true;

  @override
  void dispose() {
    super.dispose();
    _emailController.dispose();
  }

  Future passwordReset() async {
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(
                getTranslated(
                    context, 'Password reset link sent. Check your email'),
              ),
            );
          });
    } on FirebaseAuthException catch (e) {
      showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              content: Text(
                e.message.toString(),
              ),
            );
          });
    }
  }

  // Future updatePasswordInDatabase(String newPassword) async {
  //   User? user = FirebaseAuth.instance.currentUser;
  //   if (user != null) {
  //     DatabaseReference userRef =
  //         FirebaseDatabase.instance.ref('App/User/${user.uid}/Password');
  //     await userRef.set(newPassword);
  //   }
  // }

  Future<void> promptForNewPassword() async {
    TextEditingController passwordController = TextEditingController();
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Enter New Password'),
          content: TextField(
            controller: passwordController,
            decoration: InputDecoration(hintText: "New Password"),
            obscureText: true,
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Submit'),
              onPressed: () {
                if (passwordController.text.isNotEmpty) {
                  // updatePasswordInDatabase(passwordController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Reset Password"),
      ),
      body: SafeArea(
          child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormFieldStyle(
              context: context,
              hint: "Email",
              icon: Icon(
                Icons.person,
                color: kDeepPurpleColor,
              ),
              control: _emailController,
              isObsecured: false,
              validate: validateEmail,
              textInputType: TextInputType.emailAddress,
              showVisibilityToggle: false,
            ),
            20.kH,
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              child: CustomButton(
                text: getTranslated(context, "Reset Password"),
                onPressed: () async {
                  await passwordReset();
                  await promptForNewPassword(); // Prompt user for new password
                },
              ),
            )
          ],
        ),
      )),
    );
  }
}
