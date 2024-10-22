import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import '../widgets/edit_profile_widget.dart';

class EditProfileScreen extends StatefulWidget {
  final String firstName;
  final String email;
  final String phone;
  final String country;
  final String city;
  final String secondName;
  final String lastName;
  final String isSmoker; // Add this
  final String allergies; // Add this

  const EditProfileScreen({
    super.key,
    required this.firstName,
    required this.email,
    required this.phone,
    required this.country,
    required this.city,
    required this.lastName,
    required this.secondName,
    required this.isSmoker, // Add this
    required this.allergies, // Add this
  });

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _firstNameController;
  late TextEditingController _secondNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _countryController;
  late TextEditingController _cityController;
  late TextEditingController _allergiesController; // Add this

  String _isSmoker = ""; // Add this
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  bool _isChanged = false;

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(text: widget.firstName);
    _secondNameController = TextEditingController(text: widget.secondName);
    _lastNameController = TextEditingController(text: widget.lastName);
    _emailController = TextEditingController(text: widget.email);
    _phoneController = TextEditingController(text: widget.phone);
    _countryController = TextEditingController(text: widget.country);
    _cityController = TextEditingController(text: widget.city);
    _allergiesController = TextEditingController(
        text: widget.allergies); // Initialize allergies controller

    _isSmoker = widget.isSmoker; // Initialize smoker status

    _firstNameController.addListener(_onTextChanged);
    _secondNameController.addListener(_onTextChanged);
    _lastNameController.addListener(_onTextChanged);
    _emailController.addListener(_onTextChanged);
    _phoneController.addListener(_onTextChanged);
    _countryController.addListener(_onTextChanged);
    _cityController.addListener(_onTextChanged);
    _allergiesController
        .addListener(_onTextChanged); // Listen to allergies text change
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _secondNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _allergiesController.dispose(); // Dispose allergies controller
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _isChanged = _firstNameController.text != widget.firstName ||
          _emailController.text != widget.email ||
          _phoneController.text != widget.phone ||
          _countryController.text != widget.country ||
          _cityController.text != widget.city ||
          _secondNameController.text != widget.secondName ||
          _lastNameController.text != widget.lastName ||
          _allergiesController.text !=
              widget.allergies || // Check for changes in allergies
          _isSmoker != widget.isSmoker; // Check for smoker status changes
    });
  }

  Future<void> saveProfileData() async {
    if (_formKey.currentState!.validate()) {
      String? userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        DatabaseReference userRef = FirebaseDatabase.instance
            .ref()
            .child('App')
            .child('User')
            .child(userId);

        await userRef.update({
          'FirstName': _firstNameController.text,
          'SecondName': _secondNameController.text,
          'LastName': _lastNameController.text,
          'Email': _emailController.text,
          'PhoneNumber': _phoneController.text,
          'Country': _countryController.text,
          'City': _cityController.text,
          'IsSmoker': _isSmoker, // Update smoker status
          'Allergies': _allergiesController.text, // Update allergies
        });

        Navigator.pop(context, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: kIconTheme,
        centerTitle: true,
        title: Text(
          getTranslated(context, "Edit Profile"),
          style: TextStyle(
            color: kDeepPurpleColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isChanged ? () => saveProfileData() : null,
            style: TextButton.styleFrom(
              foregroundColor: _isChanged ? Colors.white : Colors.grey,
            ),
            child: Text(
              getTranslated(context, "Save"),
              style: TextStyle(
                color: _isChanged ? kDeepPurpleColor : Colors.grey,
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // First Name
                EditScreenTextFormField(
                  controller: _firstNameController,
                  labelText: getTranslated(context, "First Name"),
                  onChanged: (value) {
                    setState(() {});
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return getTranslated(
                        context,
                        "First name must not be empty",
                      );
                    }
                    return null;
                  },
                ),

                // Second Name
                EditScreenTextFormField(
                  controller: _secondNameController,
                  labelText: getTranslated(context, "Second Name"),
                  onChanged: (value) {
                    setState(() {});
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return getTranslated(
                        context,
                        "Second name must not be empty",
                      );
                    }
                    return null;
                  },
                ),

                // Last Name
                EditScreenTextFormField(
                  controller: _lastNameController,
                  labelText: getTranslated(context, "Last Name"),
                  onChanged: (value) {
                    setState(() {});
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return getTranslated(
                        context,
                        "Last name must not be empty",
                      );
                    }
                    return null;
                  },
                ),

                // Email
                EditScreenTextFormField(
                  controller: _emailController,
                  labelText: getTranslated(context, "Email"),
                  onChanged: (value) {
                    setState(() {});
                  },
                  validator: (value) {
                    if (value!.isEmpty) {
                      return getTranslated(
                        context,
                        "Email must not be empty",
                      );
                    }
                    return null;
                  },
                ),

                // Phone Number

                // Smoker dropdown
                DropdownButtonFormField<String>(
                  value: _isSmoker,
                  items: [
                    DropdownMenuItem(
                      child: Text(getTranslated(context, "Yes")),
                      value: "Yes",
                    ),
                    DropdownMenuItem(
                      child: Text(getTranslated(context, "No")),
                      value: "No",
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _isSmoker = value!;
                      _onTextChanged();
                    });
                  },
                  decoration: InputDecoration(
                    labelText: getTranslated(context, "Smoker"),
                  ),
                ),

                // Allergies input with character limit
                EditScreenTextFormField(
                  controller: _allergiesController,
                  labelText: getTranslated(context, "Allergies"),
                  onChanged: (value) {
                    if (value.length <= 75) {
                      _onTextChanged();
                    }
                  },
                  validator: (value) {
                    if (value!.length > 75) {
                      return getTranslated(
                        context,
                        "Allergies must not exceed 75 characters",
                      );
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
