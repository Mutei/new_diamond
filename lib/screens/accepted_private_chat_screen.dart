import 'package:diamond_host_admin/widgets/reused_appbar.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../screens/private_chat_screen.dart';
import '../backend/user_service.dart';
import '../localization/language_constants.dart';

class AcceptedPrivateChatScreen extends StatefulWidget {
  const AcceptedPrivateChatScreen({Key? key}) : super(key: key);

  @override
  _AcceptedPrivateChatScreenState createState() =>
      _AcceptedPrivateChatScreenState();
}

class _AcceptedPrivateChatScreenState extends State<AcceptedPrivateChatScreen> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  final UserService _userService = UserService();

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(getTranslated(context, "Accepted Private Chats")),
        ),
        body: Center(
          child: Text(
            getTranslated(context, "Please log in to view chats."),
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ),
      );
    }

    return Scaffold(
      appBar:
          ReusedAppBar(title: getTranslated(context, "Accepted Private Chats")),
      body: StreamBuilder<DatabaseEvent>(
        stream: _dbRef
            .child('App/PrivateChat') // Query the PrivateChat node
            .onValue,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            DataSnapshot dataValues = snapshot.data!.snapshot;
            if (dataValues.value == null) {
              return Center(
                child: Text(
                  getTranslated(context, "No accepted private chats."),
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              );
            }

            Map<dynamic, dynamic> chatsMap =
                dataValues.value as Map<dynamic, dynamic>;

            // Filter chats where the current user is a participant
            List<Map<String, dynamic>> userChats = [];
            chatsMap.forEach((key, value) {
              Map<String, dynamic> chatData = Map<String, dynamic>.from(value);
              if (chatData['participants'] != null &&
                  (chatData['participants'][_currentUser!.uid] == true)) {
                chatData['chatId'] = key; // Add chatId for reference
                userChats.add(chatData);
              }
            });

            if (userChats.isEmpty) {
              return Center(
                child: Text(
                  getTranslated(context, "No accepted private chats."),
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              itemCount: userChats.length,
              itemBuilder: (context, index) {
                final chat = userChats[index];
                final otherUserId = chat['participants']
                    .keys
                    .firstWhere((id) => id != _currentUser!.uid);

                return FutureBuilder<UserProfile?>(
                  future: _userService.getUserProfile(otherUserId),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return ListTile(
                        leading: const CircleAvatar(
                          child: CircularProgressIndicator(),
                        ),
                        title: const Text('Loading...'),
                        subtitle: const Text('Fetching user details'),
                      );
                    }

                    String otherUserName = userSnapshot.data != null
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
                      title: Text(otherUserName),
                      subtitle: Text(
                        getTranslated(context, "Tap to open chat"),
                        style: const TextStyle(color: Colors.grey),
                      ),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => PrivateChatScreen(
                            chatId: chat['chatId'],
                            otherUserId: otherUserId,
                          ),
                        ));
                      },
                    );
                  },
                );
              },
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                getTranslated(context, "Error loading chats."),
                style: TextStyle(color: Colors.red, fontSize: 16),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}
