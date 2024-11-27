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
    String requestId =
        _database.child('App/privateChatRequests/$recipientId').push().key!;
    await _database
        .child('App/privateChatRequests/$recipientId/$requestId')
        .set({
      'senderId': senderId,
      'senderName': senderName,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Accept a private chat request
  Future<String> acceptPrivateChatRequest({
    required String recipientId,
    required String requestId,
    required String senderId,
    required String senderName,
  }) async {
    String chatId = generateChatId(senderId, recipientId);

    // Create the private chat room
    await _database.child('App/privateChats/$chatId/participants').set({
      senderId: true,
      recipientId: true,
    });

    // Remove the request
    await _database
        .child('App/privateChatRequests/$recipientId/$requestId')
        .remove();

    return chatId;
  }

  // Reject a private chat request
  Future<void> rejectPrivateChatRequest({
    required String recipientId,
    required String requestId,
  }) async {
    await _database
        .child('App/privateChatRequests/$recipientId/$requestId')
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
        _database.child('App/privateChats/$chatId/messages').push().key!;
    await _database
        .child('App/privateChats/$chatId/messages/$messageId')
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
        .child('App/privateChats/$chatId/messages/$messageId/reactions/$userId')
        .set(reaction);
  }

  // Remove a reaction from a message in a private chat
  Future<void> removeReaction(
      String chatId, String messageId, String userId) async {
    await _database
        .child('App/privateChats/$chatId/messages/$messageId/reactions/$userId')
        .remove();
  }

  // Stream for private chat messages
  Stream<DatabaseEvent> getPrivateMessagesStream(String chatId) {
    return _database
        .child('App/privateChats/$chatId/messages')
        .orderByChild('timestamp')
        .onValue;
  }
}
