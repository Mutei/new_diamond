// lib/screens/estate_chat_screen.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../backend/chat_service.dart';
import '../backend/user_service.dart';
import '../constants/colors.dart';
import '../widgets/message_bubble.dart';
import '../localization/language_constants.dart';

class EstateChatScreen extends StatefulWidget {
  final String estateId;
  final String estateNameEn;
  final String estateNameAr;

  const EstateChatScreen({
    Key? key,
    required this.estateId,
    required this.estateNameEn,
    required this.estateNameAr,
  }) : super(key: key);

  @override
  _EstateChatScreenState createState() => _EstateChatScreenState();
}

class _EstateChatScreenState extends State<EstateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ChatService _chatService = ChatService();
  final UserService _userService = UserService();
  late DatabaseReference _chatRef;

  // Message being replied to
  Map<String, dynamic>? _replyMessage;

  // StreamController for broadcasting hide events
  final StreamController<void> _hideReactionPickersStream =
      StreamController<void>.broadcast();

  // Debounce flag to prevent spamming reactions
  bool _isReacting = false;

  @override
  void initState() {
    super.initState();
    _chatRef =
        FirebaseDatabase.instance.ref('App/EstateChats/${widget.estateId}');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _hideReactionPickersStream.close(); // Close the StreamController
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0, // Since ListView is reversed, minScrollExtent is 0.0
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _sendMessage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                getTranslated(context, 'Please log in to send messages.'))),
      );
      return;
    }

    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final userProfile = await _userService.getUserProfile(user.uid);
    final senderName = userProfile != null
        ? '${userProfile.firstName} ${userProfile.lastName}'
        : 'Anonymous';
    final profileImageUrl = userProfile?.profileImageUrl ?? '';

    // Add reply information if applicable
    Map<String, dynamic>? replyTo;
    if (_replyMessage != null) {
      replyTo = {
        'senderId': _replyMessage!['senderId'],
        'senderName': _replyMessage!['senderName'],
        'text': _replyMessage!['text'],
      };
    }

    final message = {
      'senderId': user.uid,
      'senderName': senderName,
      'profileImageUrl': profileImageUrl,
      'text': messageText,
      'timestamp': DateTime.now().toIso8601String(),
      'reactions': {}, // Initialize reactions as an empty map
      if (replyTo != null) 'replyTo': replyTo,
    };

    try {
      await _chatService.sendMessage(widget.estateId, message);
      _messageController.clear();
      setState(() {
        _replyMessage = null; // Clear the reply state
      });
      _scrollToBottom();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(getTranslated(
                context, 'Failed to send message. Please try again.'))),
      );
    }
  }

  void _replyToMessage(Map<String, dynamic> message) {
    setState(() {
      _replyMessage = message;
    });
    // Optionally, scroll to input field when replying
    _scrollController.animateTo(
      0.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _cancelReply() {
    setState(() {
      _replyMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayName = Localizations.localeOf(context).languageCode == 'ar'
        ? widget.estateNameAr
        : widget.estateNameEn;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          getTranslated(context, 'Chat - $displayName'),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: kPrimaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                _hideReactionPickersStream.add(null); // Broadcast hide event
              },
              behavior: HitTestBehavior.translucent, // Ensure taps pass through
              child: StreamBuilder<DatabaseEvent>(
                stream: _chatService.getMessagesStream(widget.estateId),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    List<Map<dynamic, dynamic>> messages = [];
                    DataSnapshot dataValues = snapshot.data!.snapshot;
                    if (dataValues.value != null) {
                      Map<dynamic, dynamic> map =
                          dataValues.value as Map<dynamic, dynamic>;
                      map.forEach((key, value) {
                        Map<String, dynamic> message =
                            Map<String, dynamic>.from(value);
                        message['messageId'] = key;
                        messages.add(message);
                      });
                      messages.sort((a, b) => DateTime.parse(b['timestamp'])
                          .compareTo(DateTime.parse(a['timestamp'])));
                    }

                    if (messages.isEmpty) {
                      return Center(
                        child: Text(
                          getTranslated(context,
                              'No messages yet. Start the conversation!'),
                          style:
                              TextStyle(color: Colors.grey[600], fontSize: 16),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['senderId'] ==
                            FirebaseAuth.instance.currentUser?.uid;

                        Map<dynamic, dynamic> reactions =
                            msg['reactions'] != null
                                ? Map<dynamic, dynamic>.from(msg['reactions'])
                                : {};

                        // Transform reactions to Map<String, int>
                        Map<String, int> reactionCounts = {};
                        reactions.forEach((key, value) {
                          if (value is String) {
                            reactionCounts[value] =
                                (reactionCounts[value] ?? 0) + 1;
                          } else {
                            // Handle invalid reaction format if necessary
                          }
                        });

                        Map<String, dynamic>? replyTo;
                        if (msg.containsKey('replyTo')) {
                          replyTo = Map<String, dynamic>.from(msg['replyTo']);
                        }

                        return MessageBubble(
                          messageId: msg['messageId'],
                          estateId: widget.estateId,
                          sender: msg['senderName'] ?? 'Anonymous',
                          text: msg['text'] ?? '',
                          isMe: isMe,
                          timestamp: msg['timestamp'] ?? '',
                          profileImageUrl: msg['profileImageUrl'] ?? '',
                          reactions: reactionCounts,
                          replyTo: replyTo,
                          onReply: _replyToMessage,
                          onReact: (reaction, {bool toggle = false}) =>
                              _reactToMessage(
                                  reaction, msg['messageId'], toggle),
                          hideReactionPickersStream:
                              _hideReactionPickersStream.stream,
                        );
                      },
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                        child: Text(
                            getTranslated(context, 'Error loading messages.')));
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              ),
            ),
          ),
          // Reply Preview
          if (_replyMessage != null) _buildReplyPreview(),
          const Divider(height: 1),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      color: Colors.grey[100],
      child: Row(
        children: [
          Icon(Icons.reply, color: Colors.blueAccent, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _replyMessage!['senderName'] ?? 'Anonymous',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _replyMessage!['text'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _cancelReply,
            child: const Icon(Icons.close, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
      child: SafeArea(
        child: Row(
          children: [
            // Expanded TextField
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(24.0),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: getTranslated(context, 'Type a message'),
                          border: InputBorder.none,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send Button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kPrimaryColor,
              ),
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _reactToMessage(String reaction, String messageId,
      [bool toggle = false]) async {
    if (_isReacting) return;

    _isReacting = true;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(getTranslated(context, 'Please log in to react.'))),
      );
      _isReacting = false;
      return;
    }

    try {
      if (toggle) {
        await _chatService.removeReaction(
            widget.estateId, messageId, user.uid, reaction);
      } else {
        await _chatService.addReaction(
            widget.estateId, messageId, user.uid, reaction);
      }
      print(
          'Updated reaction "$reaction" on message "$messageId" by user "${user.uid}"');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(getTranslated(
                context, 'Failed to update reaction. Please try again.'))),
      );
      print('Error updating reaction: $e');
    } finally {
      _isReacting = false;
    }
  }
}
