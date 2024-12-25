import 'package:firebase_database/firebase_database.dart';
import 'firebase_services.dart';
import 'user_service.dart'; // Ensure you have a UserService to fetch user details

class PrivateChatService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  final UserService _userService = UserService(); // Initialize UserService

  // Send a private chat request
  Future<void> sendPrivateChatRequest({
    required String senderId,
    required String receiverId,
  }) async {
    if (senderId.isEmpty || receiverId.isEmpty) {
      throw ArgumentError('Sender ID or Receiver ID cannot be empty');
    }

    // Fetch sender and receiver names
    final senderProfile = await _userService.getUserProfile(senderId);
    final receiverProfile = await _userService.getUserProfile(receiverId);

    final senderName = senderProfile != null
        ? '${senderProfile.firstName} ${senderProfile.lastName}'
        : 'Anonymous';
    final receiverName = receiverProfile != null
        ? '${receiverProfile.firstName} ${receiverProfile.lastName}'
        : 'Anonymous';

    // Create a new request ID
    String requestId = _database.child('App/PrivateChatRequest').push().key!;

    // Set the private chat request
    await _database.child('App/PrivateChatRequest/$requestId').set({
      'senderId': senderId,
      'receiverId': receiverId,
      'senderName': senderName,
      'receiverName': receiverName,
      'time': DateTime.now().toIso8601String(),
      'status': 2, // 2 indicates pending
    });

    print('Private chat request sent from $senderName to $receiverName');
  }

  // Accept a private chat request
  Future<void> acceptPrivateChatRequest({required String requestId}) async {
    // Fetch the request details
    DataSnapshot snapshot =
        await _database.child('App/PrivateChatRequest/$requestId').get();

    if (!snapshot.exists) {
      throw ArgumentError('Private chat request does not exist.');
    }

    Map<dynamic, dynamic> requestData = snapshot.value as Map<dynamic, dynamic>;

    String senderId = requestData['senderId'];
    String receiverId = requestData['receiverId'];
    String senderName = requestData['senderName'];
    String receiverName = requestData['receiverName'];

    // Update the status to 1 (Accepted)
    await _database.child('App/PrivateChatRequest/$requestId/status').set(1);

    // Generate a unique chat ID
    String chatId = generateChatId(senderId, receiverId);

    // Create the PrivateChat node
    await _database.child('App/PrivateChat/$chatId').set({
      'participants': {
        senderId: true,
        receiverId: true,
      },
      'time': DateTime.now().toIso8601String(),
      'messages': {}, // Initialize an empty messages node
    });

    print('Private chat request $requestId accepted. Chat ID: $chatId');
  }

  // Reject a private chat request
  Future<void> rejectPrivateChatRequest({
    required String requestId,
  }) async {
    // Update the status to 0 (Rejected)
    await _database.child('App/PrivateChatRequest/$requestId/status').set(0);
    print('Private chat request $requestId rejected.');
  }

  // Generate a unique chat ID based on user IDs
  String generateChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  // Send a message in a private chat
  Future<void> sendMessage({
    required String chatId, // This is user1ID_user2ID
    required Map<String, dynamic> message,
  }) async {
    String messageId =
        _database.child('App/PrivateChat/$chatId/messages').push().key!;
    await _database
        .child('App/PrivateChat/$chatId/messages/$messageId')
        .set(message);

    print('Message sent in chat $chatId with message ID $messageId');

    // Extract senderId from the message
    final senderId = message['senderId'];

    // Extract user1ID and user2ID from the chatId
    final userIds = chatId.split('_');
    if (userIds.length != 2) {
      print('Invalid chatId format. Expected user1ID_user2ID.');
      return;
    }

    final user1ID = userIds[0];
    final user2ID = userIds[1];

    // Determine the receiverId (the user who is not the sender)
    final receiverId = (senderId == user1ID) ? user2ID : user1ID;

    // Fetch the receiver's FCM token
    DatabaseReference userRef = _database.child('App/User/$receiverId');
    DataSnapshot tokenSnapshot = await userRef.child('Token').get();
    String receiverToken = tokenSnapshot.value?.toString() ?? "";

    if (receiverToken.isNotEmpty) {
      await FirebaseServices().sendNotificationToProvider(
        receiverToken,
        message['senderName'] ?? 'Anonymous',
        message['text'] ?? '',
      );
      print('Notification sent to $receiverId for new message.');
    } else {
      print('No FCM token found for receiver: $receiverId');
    }
  }

  // Add a reaction to a message in a private chat
  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String reaction,
  }) async {
    await _database
        .child('App/PrivateChat/$chatId/messages/$messageId/reactions/$userId')
        .set(reaction);
    print('Reaction added to message $messageId by user $userId');
  }

  // Remove a reaction from a message in a private chat
  Future<void> removeReaction(
      String chatId, String messageId, String userId) async {
    await _database
        .child('App/PrivateChat/$chatId/messages/$messageId/reactions/$userId')
        .remove();
    print('Reaction removed from message $messageId by user $userId');
  }

  // Stream for private chat messages
  Stream<DatabaseEvent> getPrivateMessagesStream(String chatId) {
    return _database
        .child('App/PrivateChat/$chatId/messages')
        .orderByChild('timestamp')
        .onValue;
  }

  // Stream for incoming private chat requests
  Stream<List<PrivateChatRequest>> getIncomingRequests(String receiverId) {
    return _database
        .child('App/PrivateChatRequest')
        .orderByChild('receiverId')
        .equalTo(receiverId)
        .onValue
        .map((event) {
      List<PrivateChatRequest> requests = [];
      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> map =
            event.snapshot.value as Map<dynamic, dynamic>;
        map.forEach((key, value) {
          Map<String, dynamic> data = Map<String, dynamic>.from(value);
          if (data['status'] == 2) {
            // Only pending requests
            requests.add(PrivateChatRequest(
              requestId: key,
              senderId: data['senderId'],
              receiverId: data['receiverId'],
              senderName: data['senderName'],
              receiverName: data['receiverName'],
              time: DateTime.parse(data['time']),
              status: data['status'],
            ));
          }
        });
      }
      return requests;
    });
  }
}

// Define a model for PrivateChatRequest
class PrivateChatRequest {
  final String requestId;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String receiverName;
  final DateTime time;
  final int status;

  PrivateChatRequest({
    required this.requestId,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.receiverName,
    required this.time,
    required this.status,
  });
}
