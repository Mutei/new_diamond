// lib/screens/private_chat_screen.dart

import 'dart:async';
import 'package:diamond_host_admin/constants/colors.dart';
import 'package:diamond_host_admin/constants/styles.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../backend/private_chat_service.dart';
import '../backend/user_service.dart';
import '../widgets/message_bubble.dart';
import '../localization/language_constants.dart';
import 'package:provider/provider.dart';
import '../state_management/general_provider.dart';
import '../utils/censor_message.dart'; // Ensure censor_message is imported if needed

class PrivateChatScreen extends StatefulWidget {
  final String chatId;
  final String otherUserId;

  const PrivateChatScreen({
    Key? key,
    required this.chatId,
    required this.otherUserId,
  }) : super(key: key);

  @override
  _PrivateChatScreenState createState() => _PrivateChatScreenState();
}

class _PrivateChatScreenState extends State<PrivateChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final PrivateChatService _privateChatService = PrivateChatService();
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
    _chatRef = FirebaseDatabase.instance
        .ref('App/PrivateChat/${widget.chatId}/messages');
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
        0.0,
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

    // Censor the message if needed
    final censoredMessageText = censorMessage(messageText);

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
      'text': censoredMessageText, // Use the censored message text here
      'timestamp': DateTime.now().toIso8601String(),
      'reactions': {}, // Initialize reactions as an empty map
      if (replyTo != null) 'replyTo': replyTo,
    };

    try {
      await _privateChatService.sendMessage(
          chatId: widget.chatId, message: message);
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
        await _privateChatService.removeReaction(
            widget.chatId, messageId, user.uid);
      } else {
        await _privateChatService.addReaction(
            chatId: widget.chatId,
            messageId: messageId,
            userId: user.uid,
            reaction: reaction);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<UserProfile?>(
          future: _userService.getUserProfile(widget.otherUserId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              );
            } else if (snapshot.hasData) {
              return Text(
                snapshot.data != null
                    ? '${snapshot.data!.firstName} ${snapshot.data!.lastName}'
                    : 'Anonymous',
                style: TextStyle(color: kDeepPurpleColor),
              );
            } else {
              return Text(
                getTranslated(context, "Private Chat"),
                style: TextStyle(
                  color: kDeepPurpleColor,
                ),
              );
            }
          },
        ),
        centerTitle: true,
        iconTheme: kIconTheme,
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                _hideReactionPickersStream.add(null); // Broadcast hide event
              },
              behavior: HitTestBehavior.translucent,
              child: StreamBuilder<DatabaseEvent>(
                stream:
                    _privateChatService.getPrivateMessagesStream(widget.chatId),
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
                          }
                        });

                        Map<String, dynamic>? replyTo;
                        if (msg.containsKey('replyTo')) {
                          replyTo = Map<String, dynamic>.from(msg['replyTo']);
                        }

                        return MessageBubble(
                          messageId: msg['messageId'],
                          estateId: widget.chatId, // Renamed to chatId
                          senderId: msg['senderId'],
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
      color: Theme.of(context).brightness == Brightness.dark
          ? Colors.black
          : Colors.white,
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
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.black
                      : Colors.grey[50],
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
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        maxLength: 100,
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
                color: Colors.deepPurple,
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
}
