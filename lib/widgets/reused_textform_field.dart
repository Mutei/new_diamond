import 'package:diamond_host_admin/constants/colors.dart';
import 'package:flutter/material.dart';

class ReusedTextFormField extends StatefulWidget {
  final String hintText;
  final IconData prefixIcon;
  final bool obscureText;
  final TextEditingController? controller;

  const ReusedTextFormField({
    Key? key,
    required this.hintText,
    required this.prefixIcon,
    this.obscureText = false,
    this.controller,
  }) : super(key: key);

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
          color: Colors.deepOrange[300]!, // Adjust based on need
        ),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextFormField(
        obscureText: _isObscure, // Controls the obscure text behavior
        controller: widget.controller,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: widget.hintText,
          prefixIcon: Icon(
            widget.prefixIcon,
            color: kSecondaryGradient, // Adjust based on need
          ),
          suffixIcon: widget.obscureText
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                    });
                  },
                )
              : null, // Only show the toggle icon for password fields
          hintStyle: TextStyle(color: Colors.grey), // Adjust based on need
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
      ),
    );
  }
}
