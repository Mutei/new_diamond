// lib/screens/upgrade_account_screen.dart

import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/localization/language_constants.dart';
import 'package:diamond_host_admin/widgets/reused_appbar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:diamond_host_admin/constants/styles.dart';
import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import '../utils/failure_dialogue.dart';
import '../utils/success_dialogue.dart';
import '../widgets/type_account_widget.dart'; // Import the new widget
import '../state_management/general_provider.dart'; // Import the provider

class UpgradeAccountScreen extends StatefulWidget {
  const UpgradeAccountScreen({super.key});

  @override
  _UpgradeAccountScreenState createState() => _UpgradeAccountScreenState();
}

class _UpgradeAccountScreenState extends State<UpgradeAccountScreen> {
  bool isLoading = false;
  List<Map<String, String>> accountTypes = [
    {
      'type': '1',
      'titleKey': 'StarTitle', // Add a key for translation
      'subtitleKey': 'StarSubtitle', // Add a key for translation
    },
    {
      'type': '2',
      'titleKey': 'PremiumTitle',
      'subtitleKey': 'PremiumSubtitle',
    },
    {
      'type': '3',
      'titleKey': 'PremiumPlusTitle',
      'subtitleKey': 'PremiumPlusSubtitle',
    },
  ];

  @override
  void initState() {
    super.initState();
    // No need to fetch here as provider handles it
  }

  Future<void> _updateAccountType(String newType) async {
    final provider = Provider.of<GeneralProvider>(context, listen: false);
    setState(() {
      isLoading = true;
    });
    try {
      // Start the subscription for 1 minute
      await provider.startSubscription(newType, const Duration(days: 30));
      setState(() {
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

  // Global method for showing upgrade confirmation dialog
  void _showUpgradeConfirmationDialog(BuildContext context, String newType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Confirm Upgrade",
            style: kTeritary,
          ),
          content: Text(getTranslated(
              context, "Are you sure you want to upgrade your account?")),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text(
                getTranslated(context, "No"),
                style:
                    const TextStyle(color: kErrorColor), // Customize as needed
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog first
                _updateAccountType(newType); // Trigger account update
              },
              child: Text(
                getTranslated(context, "Yes"),
                style: const TextStyle(
                    color: kConfirmColor), // Customize as needed
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralProvider>(
      builder: (context, provider, child) {
        String selectedTypeAccount = provider.subscriptionType;
        return Scaffold(
          appBar: ReusedAppBar(
            title: getTranslated(context, "Upgrade account"),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Padding(
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
                            height: 550, // Set height of the scrollable cards
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: accountTypes.length,
                              itemBuilder: (context, index) {
                                final accountType = accountTypes[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  child: Align(
                                    alignment: Alignment.center,
                                    child: TypeAccountWidget(
                                      accountType: accountType['type']!,
                                      selectedTypeAccount: selectedTypeAccount,
                                      title: getTranslated(
                                          context, accountType['titleKey']!),
                                      subtitle: getTranslated(
                                          context, accountType['subtitleKey']!),
                                      onSelected: (String accountType) {
                                        _showUpgradeConfirmationDialog(context,
                                            accountType); // Show confirmation dialog
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}
