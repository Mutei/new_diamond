import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/language_constants.dart';
import '../main.dart';
import '../state_management/general_provider.dart';

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

pickImage(ImageSource source) async {
  final ImagePicker _imagePicker = ImagePicker();
  XFile? _file = await _imagePicker.pickImage(source: source);
  if (_file != null) {
    return await _file.readAsBytes();
  }
  print("No image is selected!");
}

showSnackBar(String content, BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(content),
    ),
  );
}

// void _showLanguageDialog(BuildContext context) {
//   showDialog(
//     context: context,
//     builder: (BuildContext context) {
//       return AlertDialog(
//         title: Text(
//           getTranslated(context, "Select Language"),
//           style: TextStyle(
//             color: kPrimaryColor,
//           ),
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             ListTile(
//               title: Text(
//                 getTranslated(context, 'English'),
//                 style: TextStyle(
//                   color: kPrimaryColor,
//                 ),
//               ),
//               onTap: () async {
//                 SharedPreferences sharedPreferences =
//                     await SharedPreferences.getInstance();
//                 sharedPreferences.setString("Language", "en");
//                 Locale newLocale = const Locale("en", "SA");
//                 MyApp.setLocale(context, newLocale);
//                 Provider.of<GeneralProvider>(context, listen: false)
//                     .updateLanguage(true);
//                 Navigator.of(context).pop();
//               },
//             ),
//             ListTile(
//               title: Text(
//                 getTranslated(context, 'Arabic'),
//                 style: TextStyle(
//                   color: kPrimaryColor,
//                 ),
//               ),
//               onTap: () async {
//                 SharedPreferences sharedPreferences =
//                     await SharedPreferences.getInstance();
//                 sharedPreferences.setString("Language", "ar");
//                 Locale newLocale = const Locale("ar", "SA");
//                 MyApp.setLocale(context, newLocale);
//                 Provider.of<GeneralProvider>(context, listen: false)
//                     .updateLanguage(false);
//                 Navigator.of(context).pop();
//               },
//             ),
//           ],
//         ),
//       );
//     },
//   );
// }
