// account_option_widget.dart
import 'package:flutter/material.dart';
import 'package:diamond_host_admin/constants/styles.dart';

class TypeAccountWidget extends StatelessWidget {
  final String accountType;
  final String selectedTypeAccount;
  final String title;
  final String subtitle;
  final Function(String) onSelected;

  const TypeAccountWidget({
    Key? key,
    required this.accountType,
    required this.selectedTypeAccount,
    required this.title,
    required this.subtitle,
    required this.onSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () {
        onSelected(accountType);
      },
      leading: Radio<String>(
        value: accountType,
        groupValue: selectedTypeAccount,
        onChanged: (String? value) {
          onSelected(value!);
        },
      ),
      title: Text(title, style: kSecondaryStyle),
      subtitle: Text(subtitle),
    );
  }
}
