// import 'package:diamond_host_admin/widgets/reused_appbar.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import '../state_management/general_provider.dart';
// import '../localization/language_constants.dart';
// import '../main.dart';
//
// class LanguageSettings extends StatelessWidget {
//   const LanguageSettings({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<GeneralProvider>(context);
//
//     return Scaffold(
//       // Light purple background
//       appBar: ReusedAppBar(
//         title: getTranslated(context, "Language Settings"),
//       ),
//       body: Column(
//         children: [
//           ListTile(
//             title: Text(
//               getTranslated(context, "English"),
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//             ),
//             trailing: Radio<bool>(
//               value: true,
//               groupValue: provider.CheckLangValue,
//               onChanged: (value) async {
//                 if (value != null) {
//                   SharedPreferences sharedPreferences =
//                       await SharedPreferences.getInstance();
//                   sharedPreferences.setString("Language", "en");
//                   Locale newLocale = const Locale("en", "SA");
//                   MyApp.setLocale(context, newLocale);
//                   provider.updateLanguage(value);
//                 }
//               },
//               activeColor: Color(0xFF6A1B9A),
//             ),
//           ),
//           ListTile(
//             title: Text(
//               getTranslated(context, "Arabic"),
//               style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
//             ),
//             trailing: Radio<bool>(
//               value: false,
//               groupValue: provider.CheckLangValue,
//               onChanged: (value) async {
//                 if (value != null) {
//                   SharedPreferences sharedPreferences =
//                       await SharedPreferences.getInstance();
//                   sharedPreferences.setString("Language", "ar");
//                   Locale newLocale = const Locale("ar", "SA");
//                   MyApp.setLocale(context, newLocale);
//                   provider.updateLanguage(value);
//                 }
//               },
//               activeColor: Color(0xFF6A1B9A),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
