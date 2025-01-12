import 'dart:io';
import 'package:diamond_host_admin/constants/colors.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:diamond_host_admin/localization/language_constants.dart'; // Ensure correct path

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
  List<Map<String, dynamic>> commentsList = [];
  String userType = "2";
  List<Map<String, dynamic>> _userEstates = [];

  // Map to hold separate controllers for each reply field
  Map<String, TextEditingController> _replyControllers = {};

  // State variables for comments expansion
  bool _isCommentsExpanded = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadUserType();
    _fetchUserEstates();

    if (widget.post['VideoUrls'] != null &&
        widget.post['VideoUrls'].isNotEmpty) {
      _initializeVideoController(widget.post['VideoUrls'][0]);
    }

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
      List<Map<String, dynamic>> userEstates = [];
      estatesData.forEach((dynamic estateType, dynamic estates) {
        if (estates is Map<dynamic, dynamic>) {
          estates.forEach((dynamic key, dynamic value) {
            if (value != null && value['IDUser'] == userId) {
              userEstates.add({
                'type': estateType.toString(),
                'data': Map<String, dynamic>.from(value),
                'id': key.toString()
              });
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
        _videoController?.play();
      });
  }

  void _listenToLikes() {
    String userId = widget.currentUserId ?? '';
    DatabaseReference postRef = FirebaseDatabase.instance
        .ref('App/AllPosts/${widget.post['postId']}/likes');

    postRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<String, dynamic> likesData =
            Map<String, dynamic>.from(event.snapshot.value as Map);
        setState(() {
          likeCount = likesData['count'] ?? 0;
          isLiked = likesData['users']?[userId] ?? false;
        });
      } else {
        setState(() {
          likeCount = 0;
          isLiked = false;
        });
      }
    });
  }

  void _listenToComments() {
    DatabaseReference commentsRef = FirebaseDatabase.instance
        .ref('App/AllPosts/${widget.post['postId']}/comments/list');

    commentsRef.onValue.listen((event) {
      if (event.snapshot.exists) {
        Map<dynamic, dynamic> commentsData =
            Map<dynamic, dynamic>.from(event.snapshot.value as Map);
        List<Map<String, dynamic>> comments = [];

        commentsData.forEach((key, value) {
          Map<String, dynamic> comment = Map<String, dynamic>.from(value);
          // Convert replies map to list
          if (comment['replies'] != null && comment['replies'] is Map) {
            Map<dynamic, dynamic> repliesMap =
                Map<String, dynamic>.from(comment['replies']);
            List<Map<String, dynamic>> replies = [];
            repliesMap.forEach((replyKey, replyValue) {
              Map<String, dynamic> reply =
                  Map<String, dynamic>.from(replyValue);
              reply['id'] = replyKey;
              replies.add(reply);
            });
            comment['replies'] = replies;
          } else {
            comment['replies'] = [];
          }
          comment['id'] = key;
          comment['showReplyField'] = comment['showReplyField'] ?? false;
          comment['isRepliesExpanded'] = comment['isRepliesExpanded'] ?? false;
          comments.add(comment);
        });

        setState(() {
          commentsList = comments;
        });
      } else {
        setState(() {
          commentsList = [];
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _videoController?.dispose();
    _commentController.dispose();
    // Dispose all reply controllers
    _replyControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  // Handle liking/unliking the post
  void _handleLike() async {
    String userId = widget.currentUserId ?? '';
    DatabaseReference postRef = FirebaseDatabase.instance
        .ref('App/AllPosts/${widget.post['postId']}/likes');

    await postRef.runTransaction((data) {
      // *CORRECTION: Replaced '||' with '??'*
      Map<String, dynamic> likesData = Map<String, dynamic>.from(
          (data as Map<dynamic, dynamic>?) ?? {'count': 0, 'users': {}});

      int currentLikeCount = likesData['count'] ?? 0;
      Map<String, dynamic> usersMap =
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

  // Add a new comment to the post
  void _addComment(String postId, String commentText) async {
    String userId = widget.currentUserId ?? '';

    String? userName = FirebaseAuth.instance.currentUser?.displayName;
    String userProfileImage = widget.currentUserProfileImage ?? '';

    if (userName == null || userName.isEmpty) {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref('App/User/$userId');
      DatabaseEvent userEvent = await userRef.once();

      if (userEvent.snapshot.exists) {
        Map<String, dynamic> userData =
            Map<String, dynamic>.from(userEvent.snapshot.value as Map);

        String firstName = userData['FirstName'] ?? '';
        String secondName = userData['SecondName'] ?? '';
        String lastName = userData['LastName'] ?? '';

        userName = (firstName + ' ' + secondName + ' ' + lastName).trim();
        if (userName.isEmpty) {
          userName = 'Unknown User';
        }

        userProfileImage = userData['ProfileImageUrl'] ?? userProfileImage;
      } else {
        userName = 'Unknown User';
      }
    }

    DatabaseReference commentsRef =
        FirebaseDatabase.instance.ref('App/AllPosts/$postId/comments/list');
    String? commentId = commentsRef.push().key;

    if (commentId != null) {
      await commentsRef.child(commentId).set({
        'text': commentText,
        'userId': userId,
        'userName': userName,
        'userProfileImage': userProfileImage,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'likes': {
          'count': 0,
          'users': {},
        },
        'replies': {},
        'isRepliesExpanded': false,
      });

      DatabaseReference commentCountRef =
          FirebaseDatabase.instance.ref('App/AllPosts/$postId/comments/count');
      await commentCountRef.set(ServerValue.increment(1));

      _commentController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated(context, "Failed to add comment") ??
              "Failed to add comment"),
        ),
      );
    }
  }

  // Handle liking/unliking a comment
  void _handleLikeComment(String commentId) async {
    String userId = widget.currentUserId ?? '';
    DatabaseReference likeRef = FirebaseDatabase.instance.ref(
        'App/AllPosts/${widget.post['postId']}/comments/list/$commentId/likes');

    await likeRef.runTransaction((data) {
      // *CORRECTION: Replaced '||' with '??'*
      Map<String, dynamic> likesData = Map<String, dynamic>.from(
          (data as Map<dynamic, dynamic>?) ?? {'count': 0, 'users': {}});

      int currentLikeCount = likesData['count'] ?? 0;
      Map<String, dynamic> usersMap =
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

  // Handle liking/unliking a reply
  void _handleLikeReply(String commentId, String replyId) async {
    String userId = widget.currentUserId ?? '';
    DatabaseReference likeRef = FirebaseDatabase.instance.ref(
        'App/AllPosts/${widget.post['postId']}/comments/list/$commentId/replies/$replyId/likes');

    await likeRef.runTransaction((data) {
      // *CORRECTION: Replaced '||' with '??'*
      Map<String, dynamic> likesData = Map<String, dynamic>.from(
          (data as Map<dynamic, dynamic>?) ?? {'count': 0, 'users': {}});

      int currentLikeCount = likesData['count'] ?? 0;
      Map<String, dynamic> usersMap =
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

  // Add a reply to a specific comment
  void _addReply(String postId, String commentId, String replyText) async {
    String userId = widget.currentUserId ?? '';

    String? userName = FirebaseAuth.instance.currentUser?.displayName;
    String userProfileImage = widget.currentUserProfileImage ?? '';

    if (userName == null || userName.isEmpty) {
      DatabaseReference userRef =
          FirebaseDatabase.instance.ref('App/User/$userId');
      DatabaseEvent userEvent = await userRef.once();

      if (userEvent.snapshot.exists) {
        Map<String, dynamic> userData =
            Map<String, dynamic>.from(userEvent.snapshot.value as Map);

        String firstName = userData['FirstName'] ?? '';
        String secondName = userData['SecondName'] ?? '';
        String lastName = userData['LastName'] ?? '';

        userName = (firstName + ' ' + secondName + ' ' + lastName).trim();
        if (userName.isEmpty) {
          userName = 'Unknown User';
        }

        userProfileImage = userData['ProfileImageUrl'] ?? userProfileImage;
      } else {
        userName = 'Unknown User';
      }
    }

    DatabaseReference repliesRef = FirebaseDatabase.instance
        .ref('App/AllPosts/$postId/comments/list/$commentId/replies');
    String? replyId = repliesRef.push().key;

    if (replyId != null) {
      await repliesRef.child(replyId).set({
        'text': replyText,
        'userId': userId,
        'userName': userName,
        'userProfileImage': userProfileImage,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'likes': {
          'count': 0,
          'users': {},
        },
      });

      // Optionally, update reply count
      DatabaseReference replyCountRef = FirebaseDatabase.instance
          .ref('App/AllPosts/$postId/comments/list/$commentId/replyCount');
      await replyCountRef.set(ServerValue.increment(1));

      // Clear the corresponding reply controller
      _replyControllers[commentId]?.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated(context, "Failed to add reply") ??
              "Failed to add reply"),
        ),
      );
    }
  }

  // Show the reply input field for a specific comment
  void _showReplyField(String commentId) {
    setState(() {
      commentsList = commentsList.map((comment) {
        if (comment['id'] == commentId) {
          comment['showReplyField'] = !(comment['showReplyField'] ?? false);
          // Initialize controller if showing reply field
          if (comment['showReplyField'] &&
              !_replyControllers.containsKey(commentId)) {
            _replyControllers[commentId] = TextEditingController();
          } else if (!comment['showReplyField']) {
            // Dispose and remove controller if hiding reply field
            _replyControllers[commentId]?.dispose();
            _replyControllers.remove(commentId);
          }
        } else {
          comment['showReplyField'] = false;
          // Dispose and remove controller for other comments
          _replyControllers[comment['id']]?.dispose();
          _replyControllers.remove(comment['id']);
        }
        return comment;
      }).toList();
    });
  }

  // Toggle expansion of all comments
  void _toggleCommentsExpansion() {
    setState(() {
      _isCommentsExpanded = !_isCommentsExpanded;
    });
  }

  // Toggle expansion of replies for a specific comment
  void _toggleRepliesExpansion(String commentId) {
    setState(() {
      commentsList = commentsList.map((comment) {
        if (comment['id'] == commentId) {
          comment['isRepliesExpanded'] =
              !(comment['isRepliesExpanded'] ?? false);
        }
        return comment;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine current theme brightness
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    // Define text colors based on theme
    Color commentTextColor = isDarkMode ? Colors.white : Colors.black;
    Color usernameTextColor = isDarkMode ? Colors.white : Colors.black;
    Color postDescriptionTextColor = isDarkMode ? Colors.white : Colors.black;

    return GestureDetector(
      onDoubleTap: _handleLike,
      child: Card(
        color: isDarkMode
            ? kDarkModeColor
            : Colors.white, // Adjust card color based on theme
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileSection(usernameTextColor),
            if (widget.post['Description'] != null)
              _buildTextContent(postDescriptionTextColor),
            _buildImageVideoContent(),
            _buildActionButtons(),
            _buildCommentSection(commentTextColor),
          ],
        ),
      ),
    );
  }

  // Build the profile section at the top of the post
  // Build the profile section at the top of the post
  Widget _buildProfileSection(Color usernameTextColor) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: widget.post['ProfileImageUrl'] != null &&
                (widget.post['ProfileImageUrl'] as String).isNotEmpty
            ? NetworkImage(widget.post['ProfileImageUrl'])
            : const AssetImage('assets/images/default.jpg') as ImageProvider,
        radius: 20,
      ),
      title: Text(
        widget.post['Username'] ?? 'Unknown Estate',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: usernameTextColor, // Dynamic color
        ),
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
                    child: Text(getTranslated(context, choice) ?? choice),
                  );
                }).toList();
              },
            )
          : null,
    );
  }

  // Build the text content of the post
  Widget _buildTextContent(Color postDescriptionTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Text(
        widget.post['Description'] ?? '',
        style: TextStyle(
          fontSize: 14,
          color: postDescriptionTextColor, // Dynamic color
        ),
      ),
    );
  }

  // Build the image and video content of the post
  Widget _buildImageVideoContent() {
    List<dynamic> imageUrls = widget.post['ImageUrls'] ?? [];
    List<dynamic> videoUrls = widget.post['VideoUrls'] ?? [];

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
            return _buildVideoPlayer(videoUrl);
          }
        },
      ),
    );
  }

  // Build the video player widget
  Widget _buildVideoPlayer(String videoUrl) {
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

  // Build the action buttons (like and comment)
  Widget _buildActionButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Like Button
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
          // Like Count
          Text(
            '$likeCount',
            style: const TextStyle(fontSize: 14),
          ),
          const SizedBox(width: 16),
          // Comment Button
          IconButton(
            icon: const Icon(Icons.comment_outlined),
            onPressed: () {
              // Optionally, scroll to comments or focus on comment input
            },
          ),
          // Comment Count
          Text(
            '${commentsList.length}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // Build the comment section with comments and replies
  Widget _buildCommentSection(Color commentTextColor) {
    // Determine the number of comments to show based on expansion state
    int commentsToShow = _isCommentsExpanded ? commentsList.length : 2;
    bool showViewAllButton = commentsList.length > 2;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // *Scrollable Comments List or Limited Comments*
          if (commentsList.isNotEmpty)
            Column(
              children: [
                ...commentsList
                    .take(commentsToShow)
                    .map((comment) =>
                        _buildCommentItem(comment, commentTextColor))
                    .toList(),
                if (!_isCommentsExpanded && showViewAllButton)
                  GestureDetector(
                    onTap: _toggleCommentsExpansion,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        // Correctly handle the placeholder {n}
                        getTranslated(context, "View all {n} comments")
                                ?.replaceFirst(
                                    "{n}", commentsList.length.toString()) ??
                            "View all ${commentsList.length} comments",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
                if (_isCommentsExpanded && showViewAllButton)
                  GestureDetector(
                    onTap: _toggleCommentsExpansion,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Text(
                        getTranslated(context, "Hide comments") ??
                            "Hide comments",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ),
                  ),
              ],
            )
          else
            const SizedBox.shrink(),
          // *Add Comment Field*
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundImage: widget.currentUserProfileImage != null &&
                        widget.currentUserProfileImage!.isNotEmpty
                    ? NetworkImage(widget.currentUserProfileImage!)
                    : const AssetImage('assets/images/default.jpg')
                        as ImageProvider,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _commentController,
                  decoration: InputDecoration(
                    hintText: getTranslated(context, 'Write a comment...') ??
                        'Write a comment...',
                    hintStyle:
                        TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    border: InputBorder.none,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send, color: Colors.blueAccent),
                onPressed: () {
                  if (_commentController.text.trim().isNotEmpty) {
                    _addComment(
                        widget.post['postId'], _commentController.text.trim());
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Build an individual comment with possible replies
  Widget _buildCommentItem(
      Map<String, dynamic> comment, Color commentTextColor) {
    // Determine the number of replies to show based on expansion state
    int repliesToShow =
        comment['isRepliesExpanded'] ? comment['replies'].length : 2;
    bool showViewAllRepliesButton = comment['replies'].length > 2;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        children: [
          // *Comment Content*
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Commenter's Profile Picture
              CircleAvatar(
                radius: 16,
                backgroundImage: comment['userProfileImage'] != null &&
                        (comment['userProfileImage'] as String).isNotEmpty
                    ? NetworkImage(comment['userProfileImage'])
                    : const AssetImage('assets/images/default.jpg')
                        as ImageProvider,
              ),
              const SizedBox(width: 8),
              // Username and Comment Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Username and Like Button
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            comment['userName'] ?? 'Unknown User',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: commentTextColor,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        // Like Button for Comment
                        GestureDetector(
                          onTap: () => _handleLikeComment(comment['id']),
                          child: Icon(
                            comment['likes'] != null &&
                                    comment['likes']['users'] != null &&
                                    widget.currentUserId != null &&
                                    comment['likes']['users']
                                        .containsKey(widget.currentUserId)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 16,
                            color: comment['likes'] != null &&
                                    comment['likes']['users'] != null &&
                                    widget.currentUserId != null &&
                                    comment['likes']['users']
                                        .containsKey(widget.currentUserId)
                                ? Colors.red
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // Like Count for Comment
                        Text(
                          '${comment['likes']?['count'] ?? 0}',
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Comment Text
                    Text(
                      comment['text'],
                      style: TextStyle(
                        color: commentTextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // *Action Buttons (Reply)*
          Padding(
            padding: const EdgeInsets.only(left: 40.0, top: 2.0),
            child: Row(
              children: [
                TextButton(
                  onPressed: () {
                    _showReplyField(comment['id']);
                  },
                  child: Text(
                    getTranslated(context, "Reply") ?? "Reply",
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          // *Display Replies*
          if (comment['replies'] != null &&
              (comment['replies'] as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 40.0),
              child: Column(
                children: [
                  ...comment['replies'].take(repliesToShow).map((reply) {
                    return _buildReplyItem(
                        comment['id'], reply, commentTextColor);
                  }).toList(),
                  if (!comment['isRepliesExpanded'] && showViewAllRepliesButton)
                    GestureDetector(
                      onTap: () => _toggleRepliesExpansion(comment['id']),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          // Correctly handle the placeholder {n}
                          getTranslated(context, "View all {n} replies")
                                  ?.replaceFirst("{n}",
                                      comment['replies'].length.toString()) ??
                              "View all ${comment['replies'].length} replies",
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ),
                    ),
                  if (comment['isRepliesExpanded'] && showViewAllRepliesButton)
                    GestureDetector(
                      onTap: () => _toggleRepliesExpansion(comment['id']),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          getTranslated(context, "Hide replies") ??
                              "Hide replies",
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          // *Reply TextField with Submit Button (Updated)*
          if (comment['showReplyField'] == true)
            Padding(
              padding:
                  const EdgeInsets.only(left: 40.0, right: 16.0, bottom: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: widget.currentUserProfileImage != null &&
                            widget.currentUserProfileImage!.isNotEmpty
                        ? NetworkImage(widget.currentUserProfileImage!)
                        : const AssetImage('assets/images/default.jpg')
                            as ImageProvider,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _replyControllers[comment['id']],
                      decoration: InputDecoration(
                        hintText: getTranslated(context, 'Write a reply...') ??
                            'Write a reply...',
                        hintStyle: TextStyle(
                            fontSize: 14, color: Colors.grey.shade500),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send,
                        color: Colors.blueAccent, size: 20),
                    onPressed: () {
                      String replyText =
                          _replyControllers[comment['id']]?.text.trim() ?? '';
                      if (replyText.isNotEmpty) {
                        _addReply(
                            widget.post['postId'], comment['id'], replyText);
                        setState(() {
                          comment['showReplyField'] = false;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Build an individual reply
  Widget _buildReplyItem(
      String commentId, Map<String, dynamic> reply, Color commentTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Replyer's Profile Picture
          CircleAvatar(
            radius: 14,
            backgroundImage: reply['userProfileImage'] != null &&
                    (reply['userProfileImage'] as String).isNotEmpty
                ? NetworkImage(reply['userProfileImage'])
                : const AssetImage('assets/images/default.jpg')
                    as ImageProvider,
          ),
          const SizedBox(width: 8),
          // Username and Reply Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Username and Like Button
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        reply['userName'] ?? 'Unknown User',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: commentTextColor,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    // Like Button for Reply
                    GestureDetector(
                      onTap: () => _handleLikeReply(commentId, reply['id']),
                      child: Icon(
                        reply['likes'] != null &&
                                reply['likes']['users'] != null &&
                                widget.currentUserId != null &&
                                reply['likes']['users']
                                    .containsKey(widget.currentUserId)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        size: 14,
                        color: reply['likes'] != null &&
                                reply['likes']['users'] != null &&
                                widget.currentUserId != null &&
                                reply['likes']['users']
                                    .containsKey(widget.currentUserId)
                            ? Colors.red
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 2),
                    // Like Count for Reply
                    Text(
                      '${reply['likes']?['count'] ?? 0}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                // Reply Text
                Text(
                  reply['text'],
                  style: TextStyle(
                    color: commentTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
