import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:valuables/auth/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/claims/claims_service.dart';
import 'package:valuables/claims/claims_request_page.dart';
import 'package:valuables/screens/chat_screen.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _authService = GetIt.I<AuthService>();
  final _supabase = Supabase.instance.client;
  final _claimsService = ClaimsService();

  final _roomsController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  StreamSubscription<List<Map<String, dynamic>>>? _realtimeSub;

  String? _userId;
  int _pendingClaimCount = 0;

  @override
  void initState() {
    super.initState();
    _userId = _authService.getCurrentUserSession()?.user.id;

    if (_userId == null) return;

    _loadPendingClaimCount();

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

  Future<void> _loadPendingClaimCount() async {
    final count = await _claimsService.fetchPendingClaimCount();
    if (mounted) setState(() => _pendingClaimCount = count);
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

    return List<Map<String, dynamic>>.from(response);
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
    _loadPendingClaimCount();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Messages'), elevation: 0),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _roomsController.stream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = snapshot.data!;

          return Column(
            children: [
              // Pending claim requests banner — only shown if count > 0
              if (_pendingClaimCount > 0)
                _buildRequestsBanner(),

              // Conversation list
              Expanded(
                child: rooms.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: rooms.length,
                        itemBuilder: (context, index) =>
                            _buildRoomTile(rooms[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRequestsBanner() {
    final primary = Theme.of(context).colorScheme.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ClaimRequestsPage()),
        );
        // Refresh count when returning from requests page
        _loadPendingClaimCount();
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? primary.withValues(alpha: 0.2)
              : primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: primary.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.mark_chat_unread_outlined, color: primary, size: 26),
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '$_pendingClaimCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message Requests',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: primary,
                    ),
                  ),
                  Text(
                    '$_pendingClaimCount person${_pendingClaimCount > 1 ? 's are' : ' is'} claiming an item you found',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: primary),
          ],
        ),
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
            'No active conversations',
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
        backgroundImage: roomImg != null
                  ? NetworkImage(roomImg)
                  : null,
        radius: 24,
        child: roomImg == null
          ? const Icon(Icons.image, size: 18)
          : null,
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