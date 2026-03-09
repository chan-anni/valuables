import 'package:flutter/material.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart' as chat_core;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:get_it/get_it.dart';
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
  final _chatController = chat_core.InMemoryChatController();
  final _chatService = GetIt.I<ChatService>();
  final _chatClient = GetIt.I<ChatClient>();

  Map<String, dynamic>? room;
  Map<String, dynamic>? user;
  String? _itemImageUrl;
  final _supabase = Supabase.instance.client;

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

    final itemData = fetchedRoom['items'] as Map<String, dynamic>?;

    // Load the chat history before updating the UI state
    await _loadHistoricalMessages();

    setState(() {
      room = fetchedRoom;
      user = fetchedUser;
      _itemImageUrl = itemData?['image_url'] as String?;
      _isLoading = false;
    });

    _chatClient.useRealtimeChat(
      roomId: widget.chatRoom,
      userId: user!['id'],
      onMessageReceived: _handleIncomingMessage,
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
        final message = chat_core.TextMessage(
          id: record['id'].toString(),
          authorId: record['author_id'],
          createdAt: DateTime.parse(record['created_at']).toUtc(),
          text: record['text'],
        );
        _chatController.insertMessage(message);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error loading history: $e")));
      }
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

    debugPrint(_itemImageUrl);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: _itemImageUrl != null
                  ? NetworkImage(_itemImageUrl!)
                  : null,
              child: _itemImageUrl == null
                  ? const Icon(Icons.image, size: 18)
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                room?['name'] ?? 'Chat',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'delete') {
                _confirmDelete(context, room!['id']); // Call your delete logic
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      'Delete Conversation',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Chat(
        chatController: _chatController,
        currentUserId: user!['id'], // Bracket notation
        onMessageSend: (text) => _handleSend(text),
        resolveUser: (chat_core.UserID id) async {
          return chat_core.User(id: id, name: user!["id"]);
        },
      ),
    );
  }

  void _handleSend(String text) async {
    if (text.trim().isEmpty) return;

    final newMessage = chat_core.TextMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      authorId: user!['id'], // Bracket notation
      createdAt: DateTime.now().toUtc(),
      text: text,
    );

    _chatController.insertMessage(newMessage);

    await _chatClient.sendMessage(roomId: widget.chatRoom, text: text);
  }

  void _handleIncomingMessage(Map<String, dynamic> record) {
    if (record['author_id'] == user!['id']) return; // Bracket notation

    final incomingMessage = chat_core.TextMessage(
      id: record['id'].toString(),
      authorId: record['author_id'],
      createdAt: DateTime.parse(record['created_at']).toUtc(),
      text: record['text'],
    );

    setState(() {
      _chatController.insertMessage(incomingMessage);
    });
  }

  void _confirmDelete(BuildContext context, String roomId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Conversation?'),
          content: const Text('Are you sure you want to delete this chat?'),
          actions: [
            // 1. The Cancel Button
            TextButton(
              onPressed: () => Navigator.pop(context), // Just closes the pop-up
              child: const Text('Cancel'),
            ),
            // 2. The Delete Button
            TextButton(
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _chatService.deleteRoom(roomId: roomId);
                if (mounted) {
                  navigator.pop(); // Closes the dialog
                  navigator.pop(); // Leaves the chat screen
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}
