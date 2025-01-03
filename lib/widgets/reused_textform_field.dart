import 'package:diamond_host_admin/constants/colors.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart'; // Import the icons_plus package

class ReusedTextFormField extends StatefulWidget {
  final String hintText;
  final IconData prefixIcon; // Update type to IconData (from icons_plus)
  final bool obscureText;
  final TextEditingController? controller;
  final String? Function(String?)? validator; // Validator function
  final TextInputType? keyboardType; // Nullable TextInputType

  const ReusedTextFormField({
    super.key,
    required this.hintText,
    required this.prefixIcon, // Expect icons_plus icons
    this.obscureText = false,
    this.controller,
    this.validator, // Add the validator here
    this.keyboardType, // Add keyboardType parameter
  });

  @override
  _ReusedTextFormFieldState createState() => _ReusedTextFormFieldState();
}

class _ReusedTextFormFieldState extends State<ReusedTextFormField> {
  bool _isObscure = true;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obscureText; // Set the initial value
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: kDeepPurpleColor, // Adjust based on need
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextFormField(
        obscureText: _isObscure, // Controls the obscure text behavior
        controller: widget.controller,
        validator: widget.validator, // Add the validator here
        keyboardType: widget.keyboardType ??
            TextInputType
                .text, // Use keyboardType if provided, else default to TextInputType.text
        style: TextStyle(
          color: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.color, // Replace bodyText1 with bodyLarge
        ),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          prefixIcon: Icon(
            widget.prefixIcon, // Use icons from icons_plus
            color: kDeepPurpleColor, // Adjust based on need
          ),
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _isObscure
                        ? Bootstrap.eye_slash
                        : Bootstrap.eye, // icons_plus eye icon
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                )
              : null, // Only show the toggle icon for password fields
          hintStyle:
              const TextStyle(color: Colors.grey), // Adjust based on need
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
