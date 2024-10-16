import 'package:diamond_host_admin/constants/colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../constants/styles.dart';
import '../localization/language_constants.dart';
import '../widgets/reused_all_posts_card.dart';
import 'add_posts_screen.dart';

class AllPostsScreen extends StatefulWidget {
  const AllPostsScreen({super.key});

  @override
  State<AllPostsScreen> createState() => _AllPostsScreenState();
}

class _AllPostsScreenState extends State<AllPostsScreen> {
  final DatabaseReference _postsRef =
      FirebaseDatabase.instance.ref("App").child("AllPosts");
  final DatabaseReference _userRef =
      FirebaseDatabase.instance.ref("App").child("User");

  String userType = "2";
  String? currentUserId;
  String? typeAccount;
  List<Map<dynamic, dynamic>> _posts = [];

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _loadUserType();
    _loadCurrentUser();
    _loadTypeAccount();
  }

  void _loadUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userType = prefs.getString("TypeUser") ?? "2";
      print("Loaded User Type: $userType");
    });
  }

  void _loadCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser;
    setState(() {
      currentUserId = user?.uid;
    });
  }

  Future<void> _loadTypeAccount() async {
    if (currentUserId != null) {
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
      }
    }
  }

  Future<void> _fetchPosts() async {
    try {
      DatabaseEvent event = await _postsRef.once();
      Map<dynamic, dynamic>? postsData =
          event.snapshot.value as Map<dynamic, dynamic>?;

      if (postsData != null) {
        List<Map<dynamic, dynamic>> postsList = [];
        for (var entry in postsData.entries) {
          Map<dynamic, dynamic> post = entry.value;
          post['postId'] = entry.key;
          if (post['Date'] != null && post['Date'] is int) {
            int timestamp = post['Date'];
            DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);
            String relativeDate = timeago.format(date, allowFromNow: true);
            post['RelativeDate'] = relativeDate;
          } else {
            post['RelativeDate'] = 'Invalid Date';
          }
          if (post['userType'] == '1' &&
              (post['typeAccount'] == '2' || post['typeAccount'] == '3')) {
            DataSnapshot userSnapshot =
                await _userRef.child(post['userId']).get();
            if (userSnapshot.exists) {
              Map<dynamic, dynamic> userData =
                  userSnapshot.value as Map<dynamic, dynamic>;
              post['UserName'] =
                  '${userData['FirstName']} ${userData['SecondName']} ${userData['LastName']}';
            } else {
              post['UserName'] = 'Unknown User';
            }
          }
          postsList.add(post);
        }

        // Sort the posts list by Date in descending order (latest post first)
        postsList.sort((a, b) => b['Date'].compareTo(a['Date']));

        setState(() {
          _posts = postsList;
        });
      } else {
        setState(() {
          _posts = []; // Ensure _posts is empty if no posts are fetched
        });
      }
    } catch (e) {
      print('Error fetching posts: $e');
      setState(() {
        _posts = []; // Ensure _posts is empty in case of an error
      });
    }
  }

  void _confirmDeletePost(String postId) async {
    bool? confirmed = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(getTranslated(context, 'Delete Post')),
          content: Text(getTranslated(
              context, 'Are you sure you want to delete this post?')),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(getTranslated(context, 'Cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(getTranslated(context, 'Delete')),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _deletePost(postId);
    }
  }

  void _deletePost(String postId) async {
    try {
      await _postsRef.child(postId).remove();
      setState(() {
        _posts.removeWhere((post) => post['postId'] == postId);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getTranslated(context, 'Post deleted successfully'),
          ),
        ),
      );
    } catch (e) {
      print('Error deleting post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getTranslated(context, 'Failed to delete post'),
          ),
        ),
      );
    }
  }

  Future<void> _refreshPosts() async {
    await _fetchPosts();
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
        actions: [
          if ((userType == '1' || userType == '2') &&
              (typeAccount == '2' || typeAccount == '3'))
            IconButton(
              icon: Icon(
                Icons.add,
                color: kDeepPurpleColor,
              ),
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddPostScreen()),
                );
                _fetchPosts();
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: _posts.isEmpty
            ? FutureBuilder(
                future: _fetchPosts(), // Ensure posts are fetched
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (_posts.isEmpty) {
                    return Center(
                      child: Text(
                        getTranslated(context, "No Posts Available"),
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    );
                  } else {
                    return ListView(
                      children: [
                        Container(height: 20),
                        _buildPostsList(),
                      ],
                    );
                  }
                },
              )
            : ListView(
                children: [
                  Container(height: 20),
                  _buildPostsList(),
                ],
              ),
      ),
    );
  }

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
          onDelete: () => _confirmDeletePost(post['postId']),
          currentUserTypeAccount: typeAccount, // Pass currentUserTypeAccount
        );
      },
    );
  }
}
