import 'dart:io';

import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/widgets/reused_elevated_button.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/styles.dart';
import '../localization/language_constants.dart';

class AddPostScreen extends StatefulWidget {
  final Map<dynamic, dynamic>? post;

  const AddPostScreen({super.key, this.post});

  @override
  State<AddPostScreen> createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _textController = TextEditingController();
  String _postId = '';
  List<File> _imageFiles = [];
  List<File> _videoFiles = []; // New list to hold video files
  final ImagePicker _picker = ImagePicker();
  String? _selectedEstate;
  List<Map<dynamic, dynamic>> _userEstates = [];
  String userType = "2";
  String? typeAccount;
  bool _isLoading = false; // For managing the loading state

  @override
  void initState() {
    super.initState();
    if (widget.post != null) {
      _postId = widget.post!['postId'];
      _titleController.text = widget.post!['Description'];
      _textController.text = widget.post!['Text'];
      _selectedEstate = widget.post!['EstateType'];
    }
    _fetchUserEstates();
    _loadUserType();
    _loadTypeAccount();
  }

  Future<void> _loadUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userType = prefs.getString("TypeUser") ?? "2";
      print("Loaded User Type: $userType");
    });
  }

  Future<void> _loadTypeAccount() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DatabaseReference typeAccountRef = FirebaseDatabase.instance
          .ref("App")
          .child("User")
          .child(user.uid)
          .child("TypeAccount");
      DataSnapshot snapshot = await typeAccountRef.get();
      if (snapshot.exists) {
        setState(() {
          typeAccount = snapshot.value.toString();
          print("Loaded Type Account: $typeAccount");
        });
      } else {
        print("Type Account does not exist.");
      }
    }
  }

  Future<void> _fetchUserEstates() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not authenticated');
      return;
    }
    String userId = user.uid;

    DatabaseReference estateRef =
        FirebaseDatabase.instance.ref("App").child("Estate");
    DatabaseEvent estateEvent = await estateRef.once();
    Map<dynamic, dynamic>? estatesData =
        estateEvent.snapshot.value as Map<dynamic, dynamic>?;

    if (estatesData != null) {
      List<Map<dynamic, dynamic>> userEstates = [];
      print('Fetched Estates Data: $estatesData');

      estatesData.forEach((estateType, estates) {
        if (estates is Map<dynamic, dynamic>) {
          estates.forEach((key, value) {
            if (value != null && value['IDUser'] == userId) {
              // Added null check here
              print('Estate Key: $key, Value: $value');
              userEstates.add({'type': estateType, 'data': value, 'id': key});
            }
          });
        } else if (estates is List) {
          for (var value in estates) {
            if (value != null && value['IDUser'] == userId) {
              // Added null check here
              print('Estate Value in List: $value');
              userEstates.add(
                  {'type': estateType, 'data': value, 'id': value['IDEstate']});
            }
          }
        } else {
          print('Unexpected type for estates: ${estates.runtimeType}');
        }
      });

      setState(() {
        _userEstates = userEstates;
        print('User Estates: $_userEstates');
        if (_userEstates.isNotEmpty &&
            !_userEstates.any((estate) => estate['id'] == _selectedEstate)) {
          _selectedEstate = _userEstates.first['id'];
          print('Default _selectedEstate set to: $_selectedEstate');
        }
      });
    } else {
      print('No estates data found.');
    }
  }

  Future<void> _pickImages() async {
    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      setState(() {
        _imageFiles =
            pickedFiles.map((pickedFile) => File(pickedFile.path)).toList();
      });
      print('Picked Images: $_imageFiles');
    } else {
      print('No images picked.');
    }
  }

  // New method to pick videos
  Future<void> _pickVideos() async {
    final pickedFile = await _picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _videoFiles.add(File(pickedFile.path));
      });
      print('Picked Video: $_videoFiles');
    } else {
      print('No video picked.');
    }
  }

  Future<void> _savePost() async {
    if (_formKey.currentState!.validate() &&
        (_selectedEstate != null || userType != "2")) {
      if (await _canAddMorePosts()) {
        setState(() {
          _isLoading = true;
        }); // Show the CircularProgressIndicator

        try {
          User? user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            print('User not authenticated');
            return;
          }
          String userId = user.uid;

          // Fetch the user's profile image URL
          String? profileImageUrl;
          DataSnapshot userSnapshot = await FirebaseDatabase.instance
              .ref("App")
              .child("User")
              .child(userId)
              .get();
          if (userSnapshot.exists) {
            Map<dynamic, dynamic> userData =
                userSnapshot.value as Map<dynamic, dynamic>;
            profileImageUrl = userData['ProfileImageUrl'];
          }

          Map<dynamic, dynamic> selectedEstate = _selectedEstate != null
              ? _userEstates.firstWhere(
                  (estate) => estate['id'] == _selectedEstate,
                  orElse: () => {},
                )
              : {};

          if (_selectedEstate != null && selectedEstate.isEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text(
                      "You don't have an estate of type $_selectedEstate")),
            );
            return;
          }

          DatabaseReference postsRef =
              FirebaseDatabase.instance.ref("App").child("AllPosts");

          if (_postId.isEmpty) {
            _postId = postsRef.push().key!;
          }

          List<String> imageUrls = [];
          for (File imageFile in _imageFiles) {
            UploadTask uploadTask = FirebaseStorage.instance
                .ref()
                .child('post_images')
                .child('$_postId${imageFile.path.split('/').last}')
                .putFile(imageFile);
            TaskSnapshot snapshot = await uploadTask;
            String imageUrl = await snapshot.ref.getDownloadURL();
            imageUrls.add(imageUrl);
          }

          List<String> videoUrls = []; // New list to hold uploaded video URLs
          for (File videoFile in _videoFiles) {
            UploadTask uploadTask = FirebaseStorage.instance
                .ref()
                .child('post_videos')
                .child('$_postId${videoFile.path.split('/').last}')
                .putFile(videoFile);
            TaskSnapshot snapshot = await uploadTask;
            String videoUrl = await snapshot.ref.getDownloadURL();
            videoUrls.add(videoUrl);
          }

          String? estateName;
          if (userType == "2") {
            estateName = selectedEstate['data']['NameEn'];
          } else {
            if (userSnapshot.exists) {
              Map<dynamic, dynamic> userData =
                  userSnapshot.value as Map<dynamic, dynamic>;
              estateName =
                  '${userData['FirstName']} ${userData['SecondName']} ${userData['LastName']}';
            } else {
              estateName = 'Unknown User';
            }
          }

          await postsRef.child(_postId).set({
            'Description': _titleController.text,
            'Date': DateTime.now().millisecondsSinceEpoch,
            'EstateName': estateName,
            'EstateType': selectedEstate['type'],
            'userId': userId,
            'userType': userType,
            'typeAccount': typeAccount,
            'ImageUrls': imageUrls,
            'VideoUrls': videoUrls, // Save video URLs in the post
            'ProfileImageUrl':
                profileImageUrl, // Add ProfileImageUrl to the post
          });

          print('Post saved successfully');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(getTranslated(context, 'Post added successfully')),
            ),
          );
          Navigator.pop(context);
        } catch (e) {
          print('Error saving post: $e');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(getTranslated(context, 'Failed to add post')),
            ),
          );
        } finally {
          setState(() {
            _isLoading = false;
          }); // Hide the CircularProgressIndicator
        }
      }
    } else {
      print('Form is not valid or estate is not selected.');
    }
  }

  Future<bool> _canAddMorePosts() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('User not authenticated');
      return false;
    }
    String userId = user.uid;

    DatabaseReference postsRef =
        FirebaseDatabase.instance.ref("App").child("AllPosts");

    DatabaseEvent postsEvent =
        await postsRef.orderByChild('userId').equalTo(userId).once();
    Map<dynamic, dynamic>? postsData =
        postsEvent.snapshot.value as Map<dynamic, dynamic>?;

    if (postsData != null) {
      int count = 0;
      DateTime now = DateTime.now();
      DateTime thirtyDaysAgo = now.subtract(Duration(days: 30));

      postsData.forEach((key, value) {
        DateTime postDate = DateTime.fromMillisecondsSinceEpoch(value['Date']);
        if (postDate.isAfter(thirtyDaysAgo)) {
          count++;
        }
      });

      int allowedPosts = 0;
      if (userType == '1' && typeAccount == '2') {
        allowedPosts = 4;
      } else if (userType == '1' && typeAccount == '3') {
        allowedPosts = 10;
      } else if (userType == '2' && typeAccount == '2') {
        allowedPosts = 4;
      } else if (userType == '2' && typeAccount == '3') {
        allowedPosts = 8;
      } else {
        _showPostLimitAlert(allowedPosts);
        return false;
      }

      if (count >= allowedPosts) {
        _showPostLimitAlert(allowedPosts);
        return false;
      }
    }
    return true;
  }

  void _showPostLimitAlert(int allowedPosts) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Post Limit Reached'),
          content: Text(
              'You have added $allowedPosts posts in a month. You cannot add more.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: kIconTheme,
        centerTitle: true,
        title: Text(
          widget.post == null ? getTranslated(context, "Post") : "Edit Post",
          style: TextStyle(
            color: kDeepPurpleColor,
          ),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    if (userType == "2")
                      DropdownButtonFormField<String>(
                        value: _selectedEstate,
                        hint: Text(getTranslated(context, "Select Estate")),
                        items: _userEstates.map((estate) {
                          return DropdownMenuItem<String>(
                            value: estate['id'],
                            child: Text(
                                '${estate['data']['NameEn']} (${estate['type']})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedEstate = value;
                          });
                          print('Selected Estate: $_selectedEstate');
                        },
                        validator: (value) {
                          if (value == null && userType == "2") {
                            print('Estate not selected, validation failed.');
                            return 'Please select an estate';
                          }
                          return null;
                        },
                      ),
                    TextFormField(
                      controller: _titleController,
                      maxLength: 120,
                      maxLines: null,
                      decoration: InputDecoration(
                          labelText: getTranslated(context, "Title")),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return getTranslated(context, 'Please enter a title');
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 20),
                    _imageFiles.isEmpty && _videoFiles.isEmpty
                        ? Text(
                            getTranslated(context, "No images selected."),
                          )
                        : Container(
                            height: 100,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount:
                                  _imageFiles.length + _videoFiles.length,
                              itemBuilder: (context, index) {
                                if (index < _imageFiles.length) {
                                  return Image.file(_imageFiles[index]);
                                } else {
                                  return Icon(Icons.videocam, size: 100);
                                }
                              },
                            ),
                          ),
                    CustomButton(
                      text: getTranslated(context, "Pick Images"),
                      onPressed: _pickImages,
                    ),
                    if (userType == "2" &&
                        (typeAccount == "2" || typeAccount == "3"))
                      ElevatedButton(
                        onPressed: _pickVideos,
                        child: Text(getTranslated(context, "Pick Videos")),
                      ),
                    CustomButton(
                      text: getTranslated(context, "Save"),
                      onPressed: _savePost,
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
