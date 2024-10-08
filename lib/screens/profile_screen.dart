import 'dart:typed_data';
import 'package:diamond_host_admin/extension/sized_box_extension.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import '../backend/profile_picture_services.dart';
import '../backend/profile_user_info_services.dart';
import '../constants/colors.dart';
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import '../utils/global_methods.dart';
import '../widgets/profile_info_text_field.dart';
import '../widgets/reused_elevated_button.dart';
import 'edit_profile_screen.dart';

class ProfileScreenUser extends StatefulWidget {
  const ProfileScreenUser({super.key});

  @override
  State<ProfileScreenUser> createState() => _ProfileScreenUserState();
}

class _ProfileScreenUserState extends State<ProfileScreenUser> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _secondNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  Uint8List? _image;
  bool _isLoading = false;
  final ProfilePictureService _profilePictureService = ProfilePictureService();
  final UserInfoService _userInfoService = UserInfoService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance
        .addPostFrameCallback((_) => afterLayoutWidgetBuild());
  }

  @override
  void dispose() {
    super.dispose();
    _firstNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _secondNameController.dispose();
    _lastNameController.dispose();
  }

  void selectImage() async {
    Uint8List im = await pickImage(ImageSource.gallery);
    setState(() {
      _image = im;
    });

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      String imageUrl =
          await _profilePictureService.uploadImageToStorage(im, userId);
      if (imageUrl.isNotEmpty) {
        await _profilePictureService.saveImageUrlToDatabase(userId, imageUrl);
        await _profilePictureService.updateProfilePictureInPosts(
            userId, imageUrl);
      }
    }
  }

  void afterLayoutWidgetBuild() async {
    Map<String, String?> userInfo = await _userInfoService.fetchUserInfo();
    setState(() {
      _firstNameController.text = userInfo['FirstName'] ?? '';
      _secondNameController.text = userInfo['SecondName'] ?? '';
      _lastNameController.text = userInfo['LastName'] ?? '';
      _emailController.text = userInfo['Email'] ?? '';
      _phoneController.text = userInfo['PhoneNumber'] ?? '';
      _countryController.text = userInfo['Country'] ?? '';
      _cityController.text = userInfo['City'] ?? '';
      if (userInfo['ProfileImageUrl'] != null &&
          userInfo['ProfileImageUrl']!.isNotEmpty) {
        loadImageFromUrl(userInfo['ProfileImageUrl']!);
      }
    });
  }

  void loadImageFromUrl(String imageUrl) async {
    try {
      final http.Response response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode == 200) {
        setState(() {
          _image = response.bodyBytes;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading image: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          getTranslated(context, 'Profile'),
          style: TextStyle(
            color: kDeepPurpleColor,
          ),
        ),
        iconTheme: kIconTheme,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 64,
                      backgroundImage: _image != null
                          ? MemoryImage(_image!)
                          : const AssetImage('assets/images/man.png')
                              as ImageProvider,
                      backgroundColor: Colors.transparent,
                      child:
                          _isLoading ? const CircularProgressIndicator() : null,
                    ),
                    Positioned(
                      bottom: -10,
                      left: 80,
                      child: IconButton(
                        onPressed: selectImage,
                        icon: const Icon(Icons.add_a_photo),
                      ),
                    ),
                  ],
                ),
                16.kH,
                CustomButton(
                    text: getTranslated(context, 'Edit Profile'),
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfileScreen(
                            firstName: _firstNameController.text,
                            secondName: _secondNameController.text,
                            lastName: _lastNameController.text,
                            email: _emailController.text,
                            phone: _phoneController.text,
                            country: _countryController.text,
                            city: _cityController.text,
                          ),
                        ),
                      );
                      if (result == true) {
                        afterLayoutWidgetBuild();
                      }
                    }),
                32.kH,
                ProfileInfoTextField(
                  textEditingController: _firstNameController,
                  textInputType: TextInputType.text,
                  iconData: Icons.person,
                  iconColor: kDeepPurpleColor,
                ),
                24.kH,
                ProfileInfoTextField(
                  textEditingController: _secondNameController,
                  textInputType: TextInputType.text,
                  iconData: Icons.person,
                  iconColor: kDeepPurpleColor,
                ),
                24.kH,
                ProfileInfoTextField(
                  textEditingController: _lastNameController,
                  textInputType: TextInputType.text,
                  iconData: Icons.person,
                  iconColor: kDeepPurpleColor,
                ),
                24.kH,
                ProfileInfoTextField(
                  textEditingController: _emailController,
                  textInputType: TextInputType.text,
                  iconData: Icons.email,
                  iconColor: kDeepPurpleColor,
                ),
                24.kH,
                ProfileInfoTextField(
                  textEditingController: _phoneController,
                  textInputType: TextInputType.text,
                  iconData: Icons.phone,
                  iconColor: kDeepPurpleColor,
                ),
                24.kH,
                ProfileInfoTextField(
                  textEditingController: _countryController,
                  textInputType: TextInputType.text,
                  iconData: Icons.location_city,
                  iconColor: kDeepPurpleColor,
                ),
                24.kH,
                ProfileInfoTextField(
                  textEditingController: _cityController,
                  textInputType: TextInputType.text,
                  iconData: Icons.location_city,
                  iconColor: kDeepPurpleColor,
                ),
                24.kH,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
