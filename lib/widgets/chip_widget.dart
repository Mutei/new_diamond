import 'package:diamond_host_admin/constants/colors.dart';
import 'package:flutter/material.dart';

class ChipWidget extends StatelessWidget {
  final IconData icon;
  final String label;

  const ChipWidget({
    Key? key,
    required this.icon,
    required this.label,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 16, vertical: 10), // Increased padding
      margin: const EdgeInsets.only(
          bottom: 8), // Add margin for spacing between chips
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30), // Rounded corners
        gradient: kPrimaryGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4), // Adjusted shadow for more depth
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 20), // Adjust icon size
          const SizedBox(width: 8), // Adjusted spacing between icon and text
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14, // Slightly larger font size
                fontWeight: FontWeight.w600, // Increased font weight
              ),
              overflow:
                  TextOverflow.ellipsis, // Truncate long text with ellipsis
            ),
          ),
        ],
      ),
    );
  }
}
