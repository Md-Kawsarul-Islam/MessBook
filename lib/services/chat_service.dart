import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mess_manager/models/chat_message.dart';
import 'package:flutter/foundation.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Send a message
  Future<bool> sendMessage(String hostelId, ChatMessage message) async {
    try {
      await _firestore
          .collection('hostels')
          .doc(hostelId)
          .collection('messages')
          .add(message.toFirestore());
      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  // Stream messages
  Stream<List<ChatMessage>> getMessagesStream(String hostelId) {
    return _firestore
        .collection('hostels')
        .doc(hostelId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => ChatMessage.fromFirestore(doc))
              .toList();
        });
  }
}
