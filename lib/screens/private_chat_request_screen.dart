import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

import '../backend/private_chat_service.dart';
import '../backend/user_service.dart';
import '../localization/language_constants.dart';
import '../screens/private_chat_screen.dart';
import '../widgets/reused_appbar.dart';

class PrivateChatRequestsScreen extends StatefulWidget {
  const PrivateChatRequestsScreen({Key? key}) : super(key: key);

  @override
  _PrivateChatRequestsScreenState createState() =>
      _PrivateChatRequestsScreenState();
}

class _PrivateChatRequestsScreenState extends State<PrivateChatRequestsScreen> {
  final PrivateChatService _privateChatService = PrivateChatService();
  final UserService _userService = UserService();
  late User? _currentUser;

  @override
  void initState() {
    super.initState();
    _currentUser = FirebaseAuth.instance.currentUser;
    print(
        'PrivateChatRequestsScreen initialized for user: ${_currentUser?.uid}');
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(getTranslated(context, "Private Chat Requests")),
        ),
        body: Center(
          child: Text(
            getTranslated(context, "Please log in to view requests."),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: ReusedAppBar(
        title: getTranslated(context, "Private Chat Requests"),
      ),
      body: StreamBuilder<List<PrivateChatRequest>>(
        stream: _privateChatService.getIncomingRequests(_currentUser!.uid),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<PrivateChatRequest> requests = snapshot.data!;

            // Separate requests based on status
            List<PrivateChatRequest> pendingRequests =
                requests.where((req) => req.status == 2).toList();
            List<PrivateChatRequest> acceptedRequests =
                requests.where((req) => req.status == 1).toList();

            if (requests.isEmpty) {
              return Center(
                child: Text(
                  getTranslated(context, "No private chat requests."),
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              );
            }

            return ListView(
              children: [
                // Pending Requests Section
                if (pendingRequests.isNotEmpty)
                  _buildRequestSection(
                      context, pendingRequests, "New Chat Requests"),

                // Accepted Requests Section
                if (acceptedRequests.isNotEmpty)
                  _buildRequestSection(
                      context, acceptedRequests, "Accepted Chat Requests"),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                getTranslated(context, "Error loading requests."),
                style: TextStyle(color: Colors.red),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildRequestSection(
      BuildContext context, List<PrivateChatRequest> requests, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Title
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            getTranslated(context, title),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        // List of Requests
        ListView.builder(
          itemCount: requests.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final request = requests[index];
            return FutureBuilder<UserProfile?>(
              future: _userService.getUserProfile(request.senderId),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    leading: const CircleAvatar(
                      child: CircularProgressIndicator(),
                    ),
                    title: const Text('Loading...'),
                    subtitle: const Text('Fetching user details'),
                  );
                }

                String senderName = userSnapshot.data != null
                    ? '${userSnapshot.data!.firstName} ${userSnapshot.data!.lastName}'
                    : 'Anonymous';
                String profileImageUrl =
                    userSnapshot.data?.profileImageUrl ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: profileImageUrl.isNotEmpty
                        ? NetworkImage(profileImageUrl)
                        : const AssetImage('assets/images/default.jpg')
                            as ImageProvider,
                  ),
                  title: Text(senderName),
                  subtitle: Text(title == "New Chat Requests"
                      ? getTranslated(
                          context, "wants to start a private chat with you.")
                      : getTranslated(context, "Chat accepted.")),
                  trailing: title == "New Chat Requests"
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Accept Button
                            IconButton(
                              icon: Icon(Icons.check,
                                  color: Colors.green.shade700),
                              onPressed: () async {
                                await _acceptRequest(request.requestId);
                              },
                            ),
                            // Reject Button
                            IconButton(
                              icon:
                                  Icon(Icons.close, color: Colors.red.shade700),
                              onPressed: () async {
                                await _rejectRequest(request.requestId);
                              },
                            ),
                          ],
                        )
                      : IconButton(
                          icon: const Icon(Icons.message, color: Colors.blue),
                          onPressed: () {
                            Navigator.of(context).push(MaterialPageRoute(
                              builder: (context) => PrivateChatScreen(
                                chatId: _privateChatService.generateChatId(
                                  _currentUser!.uid,
                                  request.senderId,
                                ),
                                otherUserId: request.senderId,
                              ),
                            ));
                          },
                        ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _acceptRequest(String requestId) async {
    if (_currentUser == null) return;

    try {
      // Accept the request and update the chat details
      await _privateChatService.acceptPrivateChatRequest(requestId: requestId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getTranslated(context, "Request accepted. Chat is now available."),
          ),
        ),
      );

      setState(() {
        // Trigger UI update to reflect the changes
      });

      print('Chat request $requestId accepted.');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            getTranslated(
                context, "Failed to accept request. Please try again."),
          ),
        ),
      );
      print('Error accepting request: $e');
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    try {
      await _privateChatService.rejectPrivateChatRequest(requestId: requestId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated(context, "Request rejected.")),
        ),
      );

      print('Chat request $requestId rejected.');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getTranslated(
              context, "Failed to reject request. Please try again.")),
        ),
      );
      print('Error rejecting request: $e');
    }
  }
}
