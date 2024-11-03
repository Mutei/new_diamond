import 'dart:io';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diamond_host_admin/localization/language_constants.dart';

class ReusedAllPostsCards extends StatefulWidget {
  final Map post;
  final String? currentUserId;
  final String? currentUserProfileImage;
  final String? currentUserTypeAccount;
  final VoidCallback onDelete;

  const ReusedAllPostsCards({
    Key? key,
    required this.post,
    required this.currentUserId,
    required this.currentUserProfileImage,
    required this.currentUserTypeAccount,
    required this.onDelete,
  }) : super(key: key);

  @override
  _ReusedAllPostsCardsState createState() => _ReusedAllPostsCardsState();
}

class _ReusedAllPostsCardsState extends State<ReusedAllPostsCards> {
  late PageController _pageController;
  VideoPlayerController? _videoController;
  TextEditingController _commentController = TextEditingController();
  bool isLiked = false;
  int likeCount = 0;
  List<dynamic> commentsList = [];
  String userType = "2";
  List<Map<dynamic, dynamic>> _userEstates = [];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadUserType();
    _fetchUserEstates();

    // Initialize video controller if the post contains videos
    if (widget.post['VideoUrls'] != null &&
        widget.post['VideoUrls'].isNotEmpty) {
      _initializeVideoController(widget.post['VideoUrls'][0]);
    }

    // Listen to changes in likes and comments
    _listenToLikes();
    _listenToComments();
  }

  Future<void> _loadUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userType = prefs.getString("TypeUser") ?? "2";
    });
  }

  Future<void> _fetchUserEstates() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    String userId = user.uid;

    DatabaseReference estateRef =
        FirebaseDatabase.instance.ref("App").child("Estate");
    DatabaseEvent estateEvent = await estateRef.once();
    Map<dynamic, dynamic>? estatesData =
        estateEvent.snapshot.value as Map<dynamic, dynamic>?;

    if (estatesData != null) {
      List<Map<dynamic, dynamic>> userEstates = [];
      estatesData.forEach((estateType, estates) {
        if (estates is Map<dynamic, dynamic>) {
          estates.forEach((key, value) {
            if (value != null && value['IDUser'] == userId) {
              userEstates.add({'type': estateType, 'data': value, 'id': key});
            }
          });
        }
      });

      setState(() {
        _userEstates = userEstates;
      });
    }
  }

  void _initializeVideoController(String videoUrl) {
    _videoController = VideoPlayerController.network(videoUrl)
      ..initialize().then((_) {
        setState(() {});
        _videoController?.setLooping(true);
        _videoController?.play(); // Automatically play the video
      });
  }

  void _listenToLikes() {
    String userId = widget.currentUserId ?? '';
    DatabaseReference postRef = FirebaseDatabase.instance
        .ref('App/AllPosts/${widget.post['postId']}/likes');

    postRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map likesData = event.snapshot.value as Map;
        setState(() {
          likeCount = likesData['count'] ?? 0;
          isLiked = likesData['users']?[userId] ?? false;
        });
      }
    });
  }

  void _listenToComments() {
    DatabaseReference commentsRef = FirebaseDatabase.instance
        .ref('App/AllPosts/${widget.post['postId']}/comments/list');

    commentsRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        setState(() {
          commentsList = (event.snapshot.value as Map).values.toList();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    _commentController.dispose();
    super.dispose();
  }

  // Method to handle like button press
  void _handleLike() async {
    String userId = widget.currentUserId ?? '';
    DatabaseReference postRef = FirebaseDatabase.instance
        .ref('App/AllPosts/${widget.post['postId']}/likes');

    await postRef.runTransaction((data) {
      Map<dynamic, dynamic> likesData =
          (data as Map<dynamic, dynamic>?) ?? {'count': 0, 'users': {}};

      int currentLikeCount = likesData['count'] ?? 0;
      Map<dynamic, dynamic> usersMap =
          Map<String, dynamic>.from(likesData['users'] ?? {});

      if (usersMap.containsKey(userId)) {
        usersMap.remove(userId);
        currentLikeCount = (currentLikeCount > 0) ? currentLikeCount - 1 : 0;
      } else {
        usersMap[userId] = true;
        currentLikeCount += 1;
      }

      likesData['count'] = currentLikeCount;
      likesData['users'] = usersMap;

      return Transaction.success(likesData);
    });
  }

  // Method to add a comment to a post
  void _addComment(String postId, String commentText) async {
    String userId = widget.currentUserId ?? '';
    String selectedEstate = widget.post['Username'] ??
        'Unknown Estate'; // Ensure this is always set

    // Fetch profile image from the post
    String estateProfileImageUrl = widget.post['ProfileImageUrl'] ?? '';

    DatabaseReference commentsRef =
        FirebaseDatabase.instance.ref('App/AllPosts/$postId/comments/list');
    String? commentId = commentsRef.push().key;

    if (commentId != null) {
      await commentsRef.child(commentId).set({
        'text': commentText,
        'userId': userId,
        'userName': selectedEstate, // Make sure selectedEstate has a value here
        'userProfileImage': estateProfileImageUrl,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });

      DatabaseReference commentCountRef =
          FirebaseDatabase.instance.ref('App/AllPosts/$postId/comments/count');
      await commentCountRef.set(ServerValue.increment(1));

      _commentController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated(context, "Failed to add comment")),
        ),
      );
    }
  }

  // Future<String?> _selectEstate() async {
  //   return await showDialog<String>(
  //     context: context,
  //     builder: (BuildContext context) {
  //       String? selectedEstate;
  //       return AlertDialog(
  //         title: Text(getTranslated(context, "Select Estate")),
  //         content: DropdownButtonFormField<String>(
  //           value: selectedEstate,
  //           hint: Text(getTranslated(context, "Choose an Estate")),
  //           items: _userEstates.map((estate) {
  //             return DropdownMenuItem<String>(
  //               value: estate['data']['NameEn'],
  //               child: Text(estate['data']['NameEn']),
  //             );
  //           }).toList(),
  //           onChanged: (value) {
  //             selectedEstate = value;
  //           },
  //         ),
  //         actions: [
  //           TextButton(
  //             child: Text(getTranslated(context, "Cancel")),
  //             onPressed: () {
  //               Navigator.of(context).pop();
  //             },
  //           ),
  //           TextButton(
  //             child: Text(getTranslated(context, "Confirm")),
  //             onPressed: () {
  //               Navigator.of(context).pop(selectedEstate);
  //             },
  //           ),
  //         ],
  //       );
  //     },
  //   );
  // }

  // Method to build the profile section at the top of each post
  Widget _buildProfileSection() {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: widget.post['ProfileImageUrl'] != null
            ? NetworkImage(widget.post['ProfileImageUrl'])
            : const AssetImage('assets/images/default_profile.png')
                as ImageProvider,
        radius: 30,
      ),
      title: Text(
        widget.post['Username'] ?? 'Unknown Estate',
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      ),
      subtitle: Text(
        widget.post['RelativeDate'] ?? 'Unknown Date',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: widget.currentUserId == widget.post['userId']
          ? PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'Delete') {
                  widget.onDelete();
                }
              },
              itemBuilder: (BuildContext context) {
                return {'Delete'}.map((String choice) {
                  return PopupMenuItem<String>(
                    value: choice,
                    child: Text(getTranslated(context, choice)),
                  );
                }).toList();
              },
            )
          : null,
    );
  }

  // Method to build the action buttons (like, comment)
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          GestureDetector(
            onDoubleTap: _handleLike,
            child: IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.grey,
              ),
              onPressed: _handleLike,
            ),
          ),
          Text(
            '$likeCount',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 16),
          IconButton(
            icon: const Icon(Icons.comment_outlined),
            onPressed: () {
              // Optionally, scroll to comment section or focus on comment field
            },
          ),
          Text(
            '${commentsList.length}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Method to build the text content of the post
  Widget _buildTextContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Text(
        widget.post['Description'] ?? '',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  // Method to build the images and videos in the post
  Widget _buildImageVideoContent() {
    List imageUrls = widget.post['ImageUrls'] ?? [];
    List videoUrls = widget.post['VideoUrls'] ?? [];

    if (imageUrls.isEmpty && videoUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 300,
      child: PageView.builder(
        controller: _pageController,
        itemCount: imageUrls.length + videoUrls.length,
        itemBuilder: (context, index) {
          if (index < imageUrls.length) {
            return Image.network(
              imageUrls[index],
              fit: BoxFit.cover,
            );
          } else {
            String videoUrl = videoUrls[index - imageUrls.length];
            VideoPlayerController videoController =
                VideoPlayerController.network(videoUrl);
            return FutureBuilder(
              future: videoController.initialize(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  videoController.setLooping(true);
                  videoController.play();
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        videoController.value.isPlaying
                            ? videoController.pause()
                            : videoController.play();
                      });
                    },
                    child: AspectRatio(
                      aspectRatio: videoController.value.aspectRatio,
                      child: VideoPlayer(videoController),
                    ),
                  );
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            );
          }
        },
      ),
    );
  }

  // Method to build the comment section
  Widget _buildCommentSection() {
    if (commentsList.isNotEmpty) {
      Map<dynamic, dynamic> latestComment = commentsList.last;
      String profileImageUrl = latestComment['userProfileImage'] ?? '';

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Column(
          children: [
            // Show the latest comment
            ListTile(
              leading: CircleAvatar(
                radius: 20,
                backgroundImage: profileImageUrl.isNotEmpty
                    ? NetworkImage(profileImageUrl)
                    : const AssetImage('assets/images/default_profile.png')
                        as ImageProvider,
              ),
              title: Text(
                latestComment['userName'] ?? 'Unknown Estate',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                latestComment['text'],
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
            if (commentsList.length > 1)
              Padding(
                padding: const EdgeInsets.only(left: 12.0),
                child: TextButton(
                  onPressed: () {
                    _showAllCommentsBottomSheet(commentsList);
                  },
                  child: Text(
                    getTranslated(context, "View all comments")!
                        .replaceAll('{count}', commentsList.length.toString()),
                    style:
                        const TextStyle(color: Colors.blueAccent, fontSize: 14),
                  ),
                ),
              ),
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: widget.currentUserProfileImage != null &&
                          widget.currentUserProfileImage!.isNotEmpty
                      ? NetworkImage(widget.currentUserProfileImage!)
                      : const AssetImage('assets/images/default_profile.png')
                          as ImageProvider,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: getTranslated(context, 'Write a comment...'),
                      hintStyle:
                          TextStyle(fontSize: 14, color: Colors.grey.shade500),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () {
                    if (_commentController.text.isNotEmpty) {
                      _addComment(
                          widget.post['postId'], _commentController.text);
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.currentUserProfileImage != null &&
                      widget.currentUserProfileImage!.isNotEmpty
                  ? NetworkImage(widget.currentUserProfileImage!)
                  : const AssetImage('assets/images/default_profile.png')
                      as ImageProvider,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _commentController,
                decoration: InputDecoration(
                  hintText: getTranslated(context, 'Write a comment...'),
                  hintStyle:
                      TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: Colors.blueAccent),
              onPressed: () {
                if (_commentController.text.isNotEmpty) {
                  _addComment(widget.post['postId'], _commentController.text);
                }
              },
            ),
          ],
        ),
      );
    }
  }

  // Method to display all comments in a bottom sheet
  void _showAllCommentsBottomSheet(List<dynamic> commentsList) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Container(
                    height: 5,
                    width: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: commentsList.length,
                    itemBuilder: (context, index) {
                      Map<dynamic, dynamic> comment = commentsList[index];
                      String profileImageUrl =
                          comment['userProfileImage'] ?? '';
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 16.0),
                        child: Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 20,
                              backgroundImage: profileImageUrl.isNotEmpty
                                  ? NetworkImage(profileImageUrl)
                                  : const AssetImage(
                                          'assets/images/default_profile.png')
                                      as ImageProvider,
                            ),
                            title: Text(
                              comment['userName'] ?? 'Unknown Estate',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              comment['text'],
                              style: const TextStyle(
                                  fontSize: 14, color: Colors.grey),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _handleLike,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(),
            if (widget.post['Description'] != null) _buildTextContent(),
            _buildImageVideoContent(),
            _buildActionButtons(),
            _buildCommentSection(),
          ],
        ),
      ),
    );
  }
}
