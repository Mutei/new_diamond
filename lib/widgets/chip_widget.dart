import 'package:flutter/material.dart';
import '../constants/colors.dart'; // Import your color constants

class IngredientTag extends StatelessWidget {
  final IconData icon;
  final String label;

  const IngredientTag({
    super.key,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: Colors.white),
      label: Text(label),
      backgroundColor: kPurpleColor, // Use your custom color
      labelStyle: const TextStyle(color: Colors.white),
    );
  }
}
