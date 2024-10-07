import 'package:diamond_host_admin/localization/language_constants.dart';
import 'package:diamond_host_admin/screens/custom_drawer.dart';
import 'package:diamond_host_admin/widgets/reused_appbar.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Main Screen"),
      ),
      drawer: const CustomDrawer(),
    );
  }
}
