import 'package:diamond_host_admin/widgets/reused_appbar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../backend/private_chat_service.dart';
import '../screens/private_chat_screen.dart';
import '../backend/user_service.dart';
import '../localization/language_constants.dart';

class PrivateChatRequestsScreen extends StatefulWidget {
  const PrivateChatRequestsScreen({Key? key}) : super(key: key);

  @override
  _PrivateChatRequestsScreenState createState() =>
      _PrivateChatRequestsScreenState();
}

class _PrivateChatRequestsScreenState extends State<PrivateChatRequestsScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final PrivateChatService _privateChatService = PrivateChatService();
  final UserService _userService = UserService();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(getTranslated(context, "Private Chat Requests")),
        ),
        body: Center(
            child: Text(
                getTranslated(context, "Please log in to view requests."))),
      );
    }

    return Scaffold(
      appBar: ReusedAppBar(
        title: (getTranslated(context, "Private Chat Requests")),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef
            .child('App/PrivateChatRequests/${_currentUser!.uid}')
            .onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            List<Map<dynamic, dynamic>> newRequests = [];
            List<Map<dynamic, dynamic>> acceptedRequests = [];
            DataSnapshot dataValues = snapshot.data!.snapshot;

            if (dataValues.value != null) {
              Map<dynamic, dynamic> map =
                  dataValues.value as Map<dynamic, dynamic>;
              map.forEach((key, value) {
                Map<String, dynamic> request = Map<String, dynamic>.from(value);
                request['requestId'] = key;
                if (request['status'] == 'accepted') {
                  acceptedRequests.add(request);
                } else {
                  newRequests.add(request);
                }
              });
            }

            return ListView(
              children: [
                // New Requests Section
                if (newRequests.isNotEmpty)
                  _buildRequestSection(
                      context, newRequests, "New Chat Requests"),

                // Accepted Requests Section
                if (acceptedRequests.isNotEmpty)
                  _buildRequestSection(
                      context, acceptedRequests, "Accepted Chat Requests"),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
                child: Text(getTranslated(context, "Error loading requests.")));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _buildRequestSection(
      BuildContext context, List requests, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            getTranslated(context, title),
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
        ),
        ListView.builder(
          itemCount: requests.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            final request = requests[index];
            return FutureBuilder<UserProfile?>(
              future: _userService.getUserProfile(request['senderId']),
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
                        : const AssetImage('assets/images/default_avatar.png')
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
                            IconButton(
                              icon: Icon(Icons.check,
                                  color: Colors.green.shade700),
                              onPressed: () async {
                                await _acceptRequest(
                                    request['requestId'], request['senderId']);
                              },
                            ),
                            IconButton(
                              icon:
                                  Icon(Icons.close, color: Colors.red.shade700),
                              onPressed: () async {
                                await _rejectRequest(request['requestId']);
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
                                  request['senderId'],
                                ),
                                otherUserId: request['senderId'],
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

  Future<void> _acceptRequest(String requestId, String senderId) async {
    if (_currentUser == null) return;

    try {
      // Fetch sender's profile to get senderName
      UserProfile? senderProfile = await _userService.getUserProfile(senderId);
      String senderName = senderProfile != null
          ? '${senderProfile.firstName} ${senderProfile.lastName}'
          : 'Anonymous';

      // Accept the request and update its status to accepted
      await _privateChatService.acceptPrivateChatRequest(
        recipientId: _currentUser!.uid,
        requestId: requestId,
        senderId: senderId,
        senderName: senderName,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(getTranslated(
                context, "Request accepted. Chat is now available."))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(getTranslated(
                context, "Failed to accept request. Please try again."))),
      );
      print('Error accepting request: $e');
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    if (_currentUser == null) return;

    try {
      await _privateChatService.rejectPrivateChatRequest(
          recipientId: _currentUser!.uid, requestId: requestId);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(getTranslated(context, "Request rejected."))),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(getTranslated(
                context, "Failed to reject request. Please try again."))),
      );
      print('Error rejecting request: $e');
    }
  }
}
