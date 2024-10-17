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
  List<Map<String, String>> accountTypes = [
    {'type': '1', 'title': 'Star', 'subtitle': 'Limited features and benefits'},
    {
      'type': '2',
      'title': 'Premium',
      'subtitle': 'Extended features with more access'
    },
    {'type': '3', 'title': 'Premium+', 'subtitle': 'All features unlocked'},
  ];

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
          _sortAccountTypes(); // Sort account types based on the current selection
        });
      }
    }
    setState(() {
      isLoading = false;
    });
  }

  void _sortAccountTypes() {
    // Sort the accountTypes list to move the user's current account type to the first position
    accountTypes.sort((a, b) {
      if (a['type'] == selectedTypeAccount) {
        return -1;
      } else if (b['type'] == selectedTypeAccount) {
        return 1;
      } else {
        return 0;
      }
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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    getTranslated(context, 'Select your account type:'),
                    style: kSecondaryStyle.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple[600], // Refine the color
                    ),
                  ),
                  20.kH,
                  // Horizontal Scrollable List of Account Types with Centered Content
                  Center(
                    child: SizedBox(
                      height: 220, // Set height of the scrollable cards
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: accountTypes.length,
                        itemBuilder: (context, index) {
                          final accountType = accountTypes[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Align(
                              alignment: Alignment.center,
                              child: TypeAccountWidget(
                                accountType: accountType['type']!,
                                selectedTypeAccount: selectedTypeAccount,
                                title: accountType['title']!,
                                subtitle: accountType['subtitle']!,
                                onSelected: (String accountType) {
                                  setState(() {
                                    selectedTypeAccount = accountType;
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const Spacer(),
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
