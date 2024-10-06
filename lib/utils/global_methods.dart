import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/constants/styles.dart';
import 'package:flutter/material.dart';

// Global method to display an error alert dialog
void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          "Login Failed",
          style: TextStyle(
            color: kError,
          ),
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              "OK",
              style: kSecondaryStyle,
            ),
          ),
        ],
      );
    },
  );
}
