import 'package:flutter/material.dart';
import 'package:mess_manager/models/chat_message.dart';
import 'package:mess_manager/services/chat_service.dart';

class ChatProvider with ChangeNotifier {
  final ChatService _chatService;
  final bool _isLoading = false;

  ChatProvider(this._chatService);

  bool get isLoading => _isLoading;

  Stream<List<ChatMessage>> getMessagesStream(String hostelId) {
    return _chatService.getMessagesStream(hostelId);
  }

  Future<bool> sendMessage(String hostelId, ChatMessage message) async {
    // We don't necessarily need to set loading for sending chat messages
    // as it's often better to render optimistic UI or just let the stream update.
    // But basic error handling is good.
    return await _chatService.sendMessage(hostelId, message);
  }
}
