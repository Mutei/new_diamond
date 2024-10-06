import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';

class ReusedAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool centerTitle;

  const ReusedAppBar({
    super.key,
    required this.title,
    this.centerTitle = true,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(color: kDeepOrange),
      ),
      centerTitle: centerTitle,
      iconTheme: kIconTheme,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
