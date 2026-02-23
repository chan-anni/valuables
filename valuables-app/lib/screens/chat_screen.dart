import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:get_it/get_it.dart';
import 'package:valuables/auth/auth_service.dart';
import 'package:valuables/chat/chat_client.dart';
import 'package:valuables/chat/chat_service.dart';

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

  @override
  void initState() {
    super.initState();
    messages = _chatService.getMessages(widget.chatRoom);
    room = _chatService.getRoom(widget.chatRoom);
    user = _chatService.getUser();

    if (room == null || user == null) {
      debugPrint("can't join the page");
      return null;
    }
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Chat(
        chatController: _chatController,
        currentUserId: 'user1',
        onMessageSend: (text) => handleSend(text),
        resolveUser: (UserID id) async {
          return User(id: id, name: 'John Doe');
        },
      ),
    );
  }

  void handleSend(String text) async {
    final user = _authService.getCurrentUserSession()!.user;
    if (text.trim().isEmpty) return;

    // 1. Create the Message object for the Local UI
    final newMessage = TextMessage(
      id: DateTime.now().millisecondsSinceEpoch
          .toString(), // Better than Random
      authorId: user.id,
      createdAt: DateTime.now().toUtc(),
      text: text,
    );

    // 2. Update the local UI immediately
    _chatController.insertMessage(newMessage);

    // 3. Send the text to Supabase
    await _chatClient.sendMessage(roomId: widget.chatRoom, text: text);
  }
}
