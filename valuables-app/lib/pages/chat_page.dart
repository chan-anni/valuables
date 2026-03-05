import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:valuables/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:valuables/screens/chat_screen.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _authService = GetIt.I<AuthService>();
  final _supabase = Supabase.instance.client;

  List<types.Room> _chatRooms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchChatRooms();
  }

  Future<void> _fetchChatRooms() async {
    final user = _authService.getCurrentUserSession()?.user;

    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // Use Supabase foreign key join syntax to fetch the room's name
      // Note: Replace "chat_room" with the actual name of your rooms table if it is different
      final response = await _supabase
          .from("chat_room_member")
          .select("chat_room_id, chat_room(name)")
          .eq("member_id", user.id);

      final List<dynamic> records = response as List<dynamic>;

      final List<types.Room> parsedRooms = records.map((record) {
        // Extract the name from the joined table data
        final roomData = record['chat_room'] as Map<String, dynamic>?;
        final roomName = roomData?['name'] ?? 'Item Discussion';

        return types.Room(
          id: record['chat_room_id'],
          type: types.RoomType.direct,
          users: [],
          name: roomName, // Pass the fetched name here
        );
      }).toList();

      if (mounted) {
        setState(() {
          _chatRooms = parsedRooms;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching chat rooms: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Messages"), elevation: 0),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _chatRooms.isEmpty
                ? _buildEmptyState()
                : ListView.separated(
                    itemCount: _chatRooms.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final room = _chatRooms[index];
                      return _buildRoomTile(room);
                    },
                  ),
          ),
        ],
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

  Widget _buildRoomTile(types.Room room) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
        child: Icon(
          Icons.inventory_2_outlined,
          color: Theme.of(context).primaryColor,
        ),
      ),
      title: Text(
        room.name ?? 'Chat ${room.id.substring(0, 4)}...',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: const Text(
        "Tap to view messages",
        style: TextStyle(color: Colors.grey),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatRoom: room.id),
          ),
        );
      },
    );
  }
}
