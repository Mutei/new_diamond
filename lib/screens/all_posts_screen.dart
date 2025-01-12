// lib/screens/all_posts_screen.dart

import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/constants/styles.dart';
import 'package:diamond_host_admin/localization/language_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../widgets/reused_all_posts_card.dart';
import 'add_posts_screen.dart';

class AllPostsScreen extends StatefulWidget {
  const AllPostsScreen({super.key});

  @override
  State<AllPostsScreen> createState() => _AllPostsScreenState();
}

class _AllPostsScreenState extends State<AllPostsScreen> {
  // Firebase references
  final DatabaseReference _postsRef =
      FirebaseDatabase.instance.ref("App").child("AllPosts");
  final DatabaseReference _userRef =
      FirebaseDatabase.instance.ref("App").child("User");

  // User and post data variables
  String userType = "1";
  String? currentUserId;
  String? typeAccount;
  String? currentUserProfileImage;
  List<Map<dynamic, dynamic>> _posts = [];
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _initialize(); // Initialize data fetching
  }

  /// Initializes data fetching by waiting for all required data to load
  Future<void> _initialize() async {
    await Future.wait([
      _loadUserType(),
      _loadCurrentUser(),
      _loadTypeAccount(),
      _fetchPosts(),
    ]);
    setState(() {
      _isLoading = false; // Data fetching complete
    });
  }

  /// Loads the user type from SharedPreferences
  Future<void> _loadUserType() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        userType = prefs.getString("TypeUser") ?? "1";
        print("Loaded User Type: $userType");
      });
    } catch (e) {
      print('Error loading user type: $e');
      setState(() {
        userType = "1"; // Default value in case of error
      });
    }
  }

  /// Loads the current authenticated user's ID and profile image from Firebase
  Future<void> _loadCurrentUser() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      setState(() {
        currentUserId = user?.uid;
      });

      if (currentUserId != null) {
        await _loadCurrentUserProfileImage();
      }
    } catch (e) {
      print('Error loading current user: $e');
      setState(() {
        currentUserId = null;
        currentUserProfileImage = null;
      });
    }
  }

  /// Loads the current user's profile image URL from Firebase
  Future<void> _loadCurrentUserProfileImage() async {
    if (currentUserId != null) {
      try {
        DatabaseReference userRef = FirebaseDatabase.instance
            .ref("App")
            .child("User")
            .child(currentUserId!);
        DataSnapshot snapshot = await userRef.get();
        if (snapshot.exists) {
          Map<dynamic, dynamic> userData =
              snapshot.value as Map<dynamic, dynamic>;
          setState(() {
            currentUserProfileImage = userData['ProfileImageUrl']?.toString();
          });
        }
      } catch (e) {
        print('Error loading profile image: $e');
        setState(() {
          currentUserProfileImage = null;
        });
      }
    }
  }

  /// Loads the type of account for the current user from Firebase
  Future<void> _loadTypeAccount() async {
    if (currentUserId != null) {
      try {
        DatabaseReference typeAccountRef = FirebaseDatabase.instance
            .ref("App")
            .child("User")
            .child(currentUserId!)
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
      } catch (e) {
        print('Error loading type account: $e');
        setState(() {
          typeAccount = null;
        });
      }
    }
  }

  /// Fetches all approved posts from Firebase
  Future<void> _fetchPosts() async {
    try {
      DatabaseEvent event = await _postsRef.once();
      Map<dynamic, dynamic>? postsData =
          event.snapshot.value as Map<dynamic, dynamic>?;

      if (postsData != null) {
        List<Map<dynamic, dynamic>> postsList = [];
        for (var entry in postsData.entries) {
          Map<dynamic, dynamic> post = Map<dynamic, dynamic>.from(entry.value);
          post['postId'] = entry.key;

          // Check the post status
          if (post['Status'] != "1") continue; // Only show approved posts

          // Handle Date
          if (post['Date'] != null && post['Date'] is int) {
            int timestamp = post['Date'];
            DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
            String relativeDate = timeago.format(date, allowFromNow: true);
            post['RelativeDate'] = relativeDate;
          } else {
            post['RelativeDate'] = 'Unknown Date';
          }

          // Fetch UserName or EstateName
          if (post['userType'] == '1') {
            try {
              DataSnapshot userSnapshot =
                  await _userRef.child(post['userId']).get();
              if (userSnapshot.exists) {
                Map<dynamic, dynamic> userData =
                    userSnapshot.value as Map<dynamic, dynamic>;
                String firstName = userData['FirstName']?.toString() ?? '';
                String secondName = userData['SecondName']?.toString() ?? '';
                String lastName = userData['LastName']?.toString() ?? '';
                post['UserName'] = '$firstName $secondName $lastName'.trim();
              } else {
                post['UserName'] = 'Unknown User';
              }
            } catch (e) {
              print('Error fetching user data for post ${post['postId']}: $e');
              post['UserName'] = 'Unknown User';
            }
          } else if (post['userType'] == '2') {
            // Fetch EstateName for userType 2
            try {
              DatabaseReference estateRef = FirebaseDatabase.instance
                  .ref('App/Estate/${post['EstateType']}/${post['userId']}');
              DataSnapshot estateSnapshot = await estateRef.get();
              if (estateSnapshot.exists) {
                Map<dynamic, dynamic> estateData =
                    estateSnapshot.value as Map<dynamic, dynamic>;
                post['UserName'] = estateData['EstateName'] ?? 'Unknown Estate';
              } else {
                post['UserName'] = 'Unknown Estate';
              }
            } catch (e) {
              print(
                  'Error fetching estate data for post ${post['postId']}: $e');
              post['UserName'] = 'Unknown Estate';
            }
          }

          postsList.add(post);
        }

        // Sort posts by Date descending
        postsList.sort((a, b) => b['Date'].compareTo(a['Date']));

        setState(() {
          _posts = postsList;
        });
      } else {
        setState(() {
          _posts = [];
        });
      }
    } catch (e) {
      print('Error fetching posts: $e');
      setState(() {
        _posts = [];
      });
    }
  }

  /// Refreshes the posts list
  Future<void> _refreshPosts() async {
    setState(() {
      _isLoading = true; // Show loading indicator during refresh
    });
    await _fetchPosts();
    setState(() {
      _isLoading = false;
    });
  }

  /// Builds the UI component for adding a new post
  Widget _buildAddPostBar() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AddPostScreen()),
        );
        _fetchPosts(); // Refresh posts after adding a new one
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Theme.of(context).brightness == Brightness.dark
            ? kDarkModeColor
            : Colors.white,
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: currentUserProfileImage != null
                  ? NetworkImage(currentUserProfileImage!)
                  : const AssetImage('assets/images/default.jpg')
                      as ImageProvider,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  getTranslated(context, "What's on your mind?"),
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the list of posts
  Widget _buildPostsList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _posts.length,
      itemBuilder: (context, index) {
        Map<dynamic, dynamic> post = _posts[index];
        return ReusedAllPostsCards(
          post: post,
          currentUserId: currentUserId,
          currentUserTypeAccount: typeAccount,
          currentUserProfileImage: currentUserProfileImage,
          onDelete: () => _confirmDeletePost(post['postId']),
        );
      },
    );
  }

  /// Confirms the deletion of a post with the user
  void _confirmDeletePost(String postId) async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(getTranslated(context, "Delete Post")),
          content: Text(getTranslated(
              context, "Are you sure you want to delete this post?")),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(getTranslated(context, "Cancel")),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(getTranslated(context, "Delete")),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _deletePost(postId);
    }
  }

  /// Deletes a post from Firebase and updates the UI
  void _deletePost(String postId) async {
    try {
      await _postsRef.child(postId).remove();
      setState(() {
        _posts.removeWhere((post) => post['postId'] == postId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated(context, "Post deleted successfully")),
        ),
      );
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated(context, "Failed to delete post")),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: kIconTheme,
        centerTitle: true,
        title: Text(
          getTranslated(context, "All Posts"),
          style: TextStyle(
            color: kDeepPurpleColor,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(), // Loading indicator
            )
          : RefreshIndicator(
              onRefresh: _refreshPosts,
              child: ListView(
                children: [
                  _buildAddPostBar(),
                  const SizedBox(height: 10),
                  _posts.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Center(
                            child: Text(
                              getTranslated(context, "No Posts Available"),
                              style: const TextStyle(
                                  fontSize: 18, color: Colors.grey),
                            ),
                          ),
                        )
                      : _buildPostsList(),
                ],
              ),
            ),
    );
  }
}
