import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as type;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:valuables/auth/auth_service.dart';
import 'package:valuables/chat/chat_client.dart';
import 'package:valuables/chat/chat_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatScreen extends StatefulWidget {
  final String chatRoom;

  const ChatScreen({super.key, required this.chatRoom});

  @override
  ChatScreenState createState() => ChatScreenState();
}

class ChatScreenState extends State<ChatScreen> {
  final _chatController = InMemoryChatController();
  final _chatService = GetIt.I<ChatService>();
  final _authService = GetIt.I<AuthService>();
  final _chatClient = GetIt.I<ChatClient>();

  late final messages;
  late final room;
  late final user;
  late RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    room = _chatService.getRoom(widget.chatRoom);
    user = _chatService.getUser();

    if (room == null || user == null) {
      debugPrint("can't join the page");
      return; // Fixed: void function cannot return null
    }

    // Initialize the channel and provide the callback for new database inserts
    _channel = _chatClient.useRealtimeChat(
      roomId: widget.chatRoom,
      userId: user.id,
      onMessageReceived: handleIncomingMessage,
    );

    // Optional: Load historical messages here
    // messages = _chatService.getMessages(widget.chatRoom);
  }

  @override
  void dispose() {
    _chatClient.disconnect(); // Clean up the Supabase subscription
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Chat(
        chatController: _chatController,
        currentUserId: user.id, // Use actual user ID instead of 'user1'
        onMessageSend: (text) => handleSend(text),
        resolveUser: (UserID id) async {
          return type.User(
            id: id,
            name: 'John Doe',
          ); // Consider fetching actual user details
        },
      ),
    );
  }

  void handleSend(String text) async {
    if (text.trim().isEmpty) return;

    // 1. Create the Message object for the Local UI (Optimistic Update)
    final newMessage = TextMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: user.id,
      createdAt: DateTime.now().toUtc(),
      text: text,
    );

    // 2. Update the local UI immediately so it feels fast
    _chatController.insertMessage(newMessage);

    // 3. Send the text to Supabase
    await _chatClient.sendMessage(roomId: widget.chatRoom, text: text);
  }

  void handleIncomingMessage(Map<String, dynamic> record) {
    // If the message was sent by the current user, ignore it.
    // We already added it locally in handleSend() via optimistic updating.
    if (record['author_id'] == user.id) return;

    final incomingMessage = TextMessage(
      id: record['id'].toString(),
      authorId: record['author_id'],
      createdAt: DateTime.parse(record['created_at']).toUtc(),
      text: record['text'],
    );

    // Add the remote message to the UI
    setState(() {
      _chatController.insertMessage(incomingMessage);
    });
  }
}
