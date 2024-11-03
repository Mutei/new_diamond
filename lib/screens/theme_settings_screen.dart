// // theme_settings_screen.dart
// import 'package:diamond_host_admin/widgets/reused_appbar.dart';
// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../state_management/general_provider.dart';
// import '../localization/language_constants.dart';
//
// class ThemeSettingsScreen extends StatelessWidget {
//   const ThemeSettingsScreen({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final provider = Provider.of<GeneralProvider>(context);
//
//     return Scaffold(
//       appBar: ReusedAppBar(
//         title: getTranslated(context, "Theme Settings"),
//       ),
//       body: Column(
//         children: [
//           ListTile(
//             title: Text(getTranslated(context, "System Mode")),
//             trailing: Radio<ThemeModeType>(
//               value: ThemeModeType.system,
//               groupValue: provider.themeMode,
//               onChanged: (value) {
//                 provider.toggleTheme(ThemeModeType.system);
//               },
//             ),
//           ),
//           ListTile(
//             title: Text(getTranslated(context, "Light Mode")),
//             trailing: Radio<ThemeModeType>(
//               value: ThemeModeType.light,
//               groupValue: provider.themeMode,
//               onChanged: (value) {
//                 provider.toggleTheme(ThemeModeType.light);
//               },
//             ),
//           ),
//           ListTile(
//             title: Text(getTranslated(context, "Dark Mode")),
//             trailing: Radio<ThemeModeType>(
//               value: ThemeModeType.dark,
//               groupValue: provider.themeMode,
//               onChanged: (value) {
//                 provider.toggleTheme(ThemeModeType.dark);
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
