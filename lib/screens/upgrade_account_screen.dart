import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import '../widgets/reused_appbar.dart';
import '../widgets/type_account_widget.dart';
import '../state_management/general_provider.dart';
import '../utils/failure_dialogue.dart';
import '../utils/success_dialogue.dart';

class UpgradeAccountScreen extends StatefulWidget {
  const UpgradeAccountScreen({super.key});

  @override
  _UpgradeAccountScreenState createState() => _UpgradeAccountScreenState();
}

class _UpgradeAccountScreenState extends State<UpgradeAccountScreen> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<GeneralProvider>(
      builder: (context, provider, child) {
        String selectedTypeAccount = provider.subscriptionType;
        List<Map<String, String>> accountTypes = [
          {
            'type': '1',
            'titleKey': 'StarTitle',
            'subtitleKey': 'StarSubtitle',
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

        if (selectedTypeAccount != "1") {
          accountTypes
              .sort((a, b) => a['type'] == selectedTypeAccount ? -1 : 1);
        }

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
                            color: Colors.purple[600],
                          ),
                        ),
                        20.kH,
                        Center(
                          child: SizedBox(
                            height: 550,
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
                                        _showUpgradeConfirmationDialog(
                                            context, accountType);
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

  Future<void> _updateAccountType(String newType) async {
    final provider = Provider.of<GeneralProvider>(context, listen: false);
    setState(() {
      isLoading = true;
    });
    try {
      await provider.startSubscription(newType, const Duration(days: 30));
      setState(() {
        isLoading = false;
      });
      _showSuccessDialog();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
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

  void _showUpgradeConfirmationDialog(BuildContext context, String newType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Upgrade", style: kTeritary),
          content: Text(getTranslated(
              context, "Are you sure you want to upgrade your account?")),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(getTranslated(context, "No"),
                  style: const TextStyle(color: kErrorColor)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateAccountType(newType);
              },
              child: Text(getTranslated(context, "Yes"),
                  style: const TextStyle(color: kConfirmColor)),
            ),
          ],
        );
      },
    );
  }
}
