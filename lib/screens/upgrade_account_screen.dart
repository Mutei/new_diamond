import 'package:diamond_host_admin/localization/language_constants.dart';
import 'package:diamond_host_admin/widgets/reused_appbar.dart';
import 'package:diamond_host_admin/widgets/reused_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:diamond_host_admin/constants/styles.dart';
import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import '../utils/failure_dialogue.dart';
import '../utils/success_dialogue.dart';
import '../widgets/type_account_widget.dart'; // Import the new widget

class UpgradeAccountScreen extends StatefulWidget {
  const UpgradeAccountScreen({super.key});

  @override
  _UpgradeAccountScreenState createState() => _UpgradeAccountScreenState();
}

class _UpgradeAccountScreenState extends State<UpgradeAccountScreen> {
  String selectedTypeAccount = '1'; // Default to Star account
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentAccountType();
  }

  Future<void> _fetchCurrentAccountType() async {
    setState(() {
      isLoading = true;
    });
    // Fetch the current TypeAccount from the Realtime Database
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      DatabaseReference ref =
          FirebaseDatabase.instance.ref().child('App').child('User').child(id);
      DatabaseEvent event = await ref.once();
      if (event.snapshot.exists) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        setState(() {
          selectedTypeAccount = data['TypeAccount'] ?? '1';
        });
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  Future<void> _updateAccountType(String newType) async {
    setState(() {
      isLoading = true;
    });
    String? id = FirebaseAuth.instance.currentUser?.uid;
    if (id != null) {
      try {
        await FirebaseDatabase.instance
            .ref()
            .child('App')
            .child('User')
            .child(id)
            .update({'TypeAccount': newType});
        setState(() {
          selectedTypeAccount = newType;
          isLoading = false;
        });
        // Show success dialog
        _showSuccessDialog();
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        // Show failure dialog
        _showFailureDialog();
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const SuccessDialog(
          text: 'Account Upgrade',
          text1: 'Your account has been successfully upgraded!',
        );
      },
    );
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return const FailureDialog(
          text: 'Upgrade Failed',
          text1: 'There was an error upgrading your account.',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Upgrade account"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select your account type:',
                    style: kSecondaryStyle,
                  ),
                  20.kH,
                  AccountOptionWidget(
                    accountType: '1',
                    selectedTypeAccount: selectedTypeAccount,
                    title: 'Star Account',
                    subtitle: 'Limited features and benefits',
                    onSelected: (String accountType) {
                      setState(() {
                        selectedTypeAccount = accountType;
                      });
                    },
                  ),
                  10.kH,
                  AccountOptionWidget(
                    accountType: '2',
                    selectedTypeAccount: selectedTypeAccount,
                    title: 'Premium Account',
                    subtitle: 'Extended features with more access',
                    onSelected: (String accountType) {
                      setState(() {
                        selectedTypeAccount = accountType;
                      });
                    },
                  ),
                  10.kH,
                  AccountOptionWidget(
                    accountType: '3',
                    selectedTypeAccount: selectedTypeAccount,
                    title: 'Premium+ Account',
                    subtitle: 'All features unlocked',
                    onSelected: (String accountType) {
                      setState(() {
                        selectedTypeAccount = accountType;
                      });
                    },
                  ),
                  Spacer(),
                  CustomButton(
                      text: getTranslated(context, "Upgrade account"),
                      onPressed: () {
                        _updateAccountType(selectedTypeAccount);
                      })
                ],
              ),
            ),
    );
  }
}
