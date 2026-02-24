import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chatCore;
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
  final _chatController = chatCore.InMemoryChatController();
  final _chatService = GetIt.I<ChatService>();
  final _authService = GetIt.I<AuthService>();
  final _chatClient = GetIt.I<ChatClient>();

  late final messages;
  Map<String, dynamic>? room;
  Map<String, dynamic>? user;
  late RealtimeChannel _channel;
  final _supabase = Supabase.instance.client; // Add this

  bool _isLoading = true; // Add a loading flag

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    final fetchedRoom = await _chatService.getRoom(widget.chatRoom);
    final fetchedUser = await _chatService.getUser();

    if (fetchedRoom == null || fetchedUser == null) {
      debugPrint("can't join the page");
      if (mounted) Navigator.of(context).pop();
      return;
    }

    // Load the chat history before updating the UI state
    await _loadHistoricalMessages();

    setState(() {
      room = fetchedRoom;
      user = fetchedUser;
      _isLoading = false;
    });

    _channel = _chatClient.useRealtimeChat(
      roomId: widget.chatRoom,
      userId: user!['id'],
      onMessageReceived: handleIncomingMessage,
    );
  }

  Future<void> _loadHistoricalMessages() async {
    try {
      final response = await _supabase
          .from('message')
          .select()
          .eq('chat_room_id', widget.chatRoom)
          .order('created_at', ascending: true); // Chat UI loads bottom-up

      final List<dynamic> records = response as List<dynamic>;

      for (var record in records) {
        final message = chatCore.TextMessage(
          id: record['id'].toString(),
          authorId: record['author_id'],
          createdAt: DateTime.parse(record['created_at']).toUtc(),
          text: record['text'],
        );
        _chatController.insertMessage(message);
      }
    } catch (e) {
      debugPrint("Error loading history: $e");
    }
  }

  @override
  void dispose() {
    _chatClient.disconnect(); // Clean up the Supabase subscription
    _chatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading spinner while fetching the user
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Chat(
        chatController: _chatController,
        currentUserId: user!['id'], // Bracket notation
        onMessageSend: (text) => handleSend(text),
        resolveUser: (chatCore.UserID id) async {
          return chatCore.User(id: id, name: 'John Doe');
        },
      ),
    );
  }

  void handleSend(String text) async {
    if (text.trim().isEmpty) return;

    final newMessage = chatCore.TextMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: user!['id'], // Bracket notation
      createdAt: DateTime.now().toUtc(),
      text: text,
    );

    _chatController.insertMessage(newMessage);

    await _chatClient.sendMessage(roomId: widget.chatRoom, text: text);
  }

  void handleIncomingMessage(Map<String, dynamic> record) {
    if (record['author_id'] == user!['id']) return; // Bracket notation

    final incomingMessage = chatCore.TextMessage(
      id: record['id'].toString(),
      authorId: record['author_id'],
      createdAt: DateTime.parse(record['created_at']).toUtc(),
      text: record['text'],
    );

    setState(() {
      _chatController.insertMessage(incomingMessage);
    });
  }
}
