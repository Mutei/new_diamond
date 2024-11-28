// lib/backend/private_chat_service.dart

import 'package:firebase_database/firebase_database.dart';

class PrivateChatService {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // Send a private chat request
  Future<void> sendPrivateChatRequest({
    required String senderId,
    required String senderName,
    required String recipientId,
    required String recipientName,
  }) async {
    if (senderId.isEmpty || senderName.isEmpty) {
      throw ArgumentError('Sender ID or name cannot be empty');
    }

    String requestId =
        _database.child('App/PrivateChatRequests/$recipientId').push().key!;
    await _database
        .child('App/PrivateChatRequests/$recipientId/$requestId')
        .set({
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Accept a private chat request
  // Accept a private chat request
  // Accept a private chat request
  Future<void> acceptPrivateChatRequest({
    required String recipientId,
    required String requestId,
    required String senderId,
    required String senderName,
  }) async {
    String chatId = generateChatId(senderId, recipientId);

    // Update the request status to "accepted"
    await _database
        .child('App/PrivateChatRequests/$recipientId/$requestId')
        .update({'status': 'accepted'});

    // Add chat information to both participants
    await _database.child('App/PrivateChats/$chatId').set({
      'participants': {senderId: true, recipientId: true},
      'lastMessage': {
        'text': 'Chat started.',
        'timestamp': DateTime.now().toIso8601String(),
        'senderId': '',
      },
    });

    // Save chat details for the sender
    await _database.child('App/Users/$senderId/Chats/$chatId').set({
      'recipientId': recipientId,
      'recipientName': await _getUserName(recipientId),
      'chatId': chatId,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Save chat details for the recipient
    await _database.child('App/Users/$recipientId/Chats/$chatId').set({
      'recipientId': senderId,
      'recipientName': senderName,
      'chatId': chatId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

// Helper function to fetch a user's name from their ID
  Future<String> _getUserName(String userId) async {
    final snapshot = await _database.child('App/User/$userId').get();
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      final firstName = data['FirstName'] ?? 'Anonymous';
      final lastName = data['LastName'] ?? '';
      return '$firstName $lastName';
    }
    return 'Anonymous';
  }

  // Reject a private chat request
  Future<void> rejectPrivateChatRequest({
    required String recipientId,
    required String requestId,
  }) async {
    await _database
        .child('App/PrivateChatRequests/$recipientId/$requestId')
        .remove();
  }

  // Generate a unique chat ID based on user IDs
  String generateChatId(String userId1, String userId2) {
    return userId1.compareTo(userId2) < 0
        ? '${userId1}_$userId2'
        : '${userId2}_$userId1';
  }

  // Send a message in a private chat
  Future<void> sendMessage({
    required String chatId,
    required Map<String, dynamic> message,
  }) async {
    String messageId =
        _database.child('App/PrivateChats/$chatId/messages').push().key!;
    await _database
        .child('App/PrivateChats/$chatId/messages/$messageId')
        .set(message);
  }

  // Add a reaction to a message in a private chat
  Future<void> addReaction({
    required String chatId,
    required String messageId,
    required String userId,
    required String reaction,
  }) async {
    await _database
        .child('App/PrivateChats/$chatId/messages/$messageId/reactions/$userId')
        .set(reaction);
  }

  // Remove a reaction from a message in a private chat
  Future<void> removeReaction(
      String chatId, String messageId, String userId) async {
    await _database
        .child('App/PrivateChats/$chatId/messages/$messageId/reactions/$userId')
        .remove();
  }

  // Stream for private chat messages
  Stream<DatabaseEvent> getPrivateMessagesStream(String chatId) {
    return _database
        .child('App/PrivateChats/$chatId/messages')
        .orderByChild('timestamp')
        .onValue;
  }
}
