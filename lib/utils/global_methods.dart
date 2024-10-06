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
            color: kErrorColor,
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

void showLoginErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          "Access Denied",
          style: TextStyle(
            color: kErrorColor,
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

void showLogoutConfirmationDialog(BuildContext context, Function onConfirm) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text(
          "Confirm Logout",
          style: TextStyle(
            color: kConfirmColor, // Customize as needed
          ),
        ),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text(
              "Cancel",
              style: TextStyle(color: Colors.grey), // Customize as needed
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog first
              onConfirm(); // Then trigger the logout
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: kConfirmColor), // Customize as needed
            ),
          ),
        ],
      );
    },
  );
}
