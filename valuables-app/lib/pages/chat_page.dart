import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:valuables/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/screens/chat_screen.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _authService = GetIt.I<AuthService>();
  final _supabase = Supabase.instance.client;

  final _roomsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSub;

  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = _authService.getCurrentUserSession()?.user.id;

    if (_userId == null) return;

    _realtimeSub = _supabase
        .from('chat_room_member')
        .stream(primaryKey: ['id'])
        .eq('member_id', _userId!)
        .asyncMap((members) => _fetchRoomDetails(members))
        .listen(
          (rooms) => _roomsController.add(rooms),
          onError: (e) => _roomsController.addError(e),
        );
  }

  @override
  void dispose() {
    _realtimeSub?.cancel();
    _roomsController.close();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetchRoomDetails(
    List<Map<String, dynamic>> members,
  ) async {
    if (members.isEmpty) return [];

    final roomIds = members.map((m) => m['chat_room_id'] as String).toList();

    final response = await _supabase
        .from('chat_room')
        .select('''
          id,
          name,
          items (image_url),
          message (text, created_at)
        ''')
        .inFilter('id', roomIds)
        .order('created_at', referencedTable: 'message', ascending: false);

    // Sort rooms by the timestamp of their latest message (newest → oldest).
    final rooms = List<Map<String, dynamic>>.from(response);

    DateTime lastMessageTime(Map<String, dynamic> room) {
      final messages = room['message'] as List<dynamic>? ?? [];
      if (messages.isEmpty) {
        // Put rooms with no messages at the bottom.
        return DateTime.fromMillisecondsSinceEpoch(0);
      }

      final first = messages.first;
      if (first is Map<String, dynamic>) {
        final raw = first['created_at']?.toString();
        if (raw != null) {
          return DateTime.tryParse(raw) ??
              DateTime.fromMillisecondsSinceEpoch(0);
        }
      }
      return DateTime.fromMillisecondsSinceEpoch(0);
    }

    rooms.sort((a, b) => lastMessageTime(b).compareTo(lastMessageTime(a)));

    return rooms;
  }

  Future<void> _refreshRooms() async {
    if (_userId == null) return;

    final members = await _supabase
        .from('chat_room_member')
        .select()
        .eq('member_id', _userId!);

    final rooms = await _fetchRoomDetails(
      List<Map<String, dynamic>>.from(members),
    );
    _roomsController.add(rooms);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Messages"), elevation: 0),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _roomsController.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data!;

          if (rooms.isEmpty) return _buildEmptyState();

          return ListView.builder(
            itemCount: rooms.length,
            itemBuilder: (context, index) => _buildRoomTile(rooms[index]),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            "No active conversations",
            style: TextStyle(color: Colors.grey, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTile(Map<String, dynamic> room) {
    final roomId = room['id'] as String;
    final roomName = room['name'] as String? ?? 'Item Discussion';
    final itemData = room['items'] as Map<String, dynamic>?;
    final roomImg = itemData?['image_url'] as String?;

    final messageList = room['message'] as List<dynamic>? ?? [];
    final lastMessage = messageList.isNotEmpty
        ? (messageList.first as Map<String, dynamic>)['text'] as String? ?? ''
        : 'Tap to start the conversation';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      leading: CircleAvatar(
        backgroundImage: NetworkImage(
          roomImg ??
              "https://zhurzsbvxcsaexcbqown.supabase.co/storage/v1/object/public/items/items/1771975266212.jpg",
        ),
        radius: 24,
      ),
      title: Text(
        roomName,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(lastMessage, style: const TextStyle(color: Colors.grey)),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ChatScreen(chatRoom: roomId)),
        );
        _refreshRooms();
      },
    );
  }
}
