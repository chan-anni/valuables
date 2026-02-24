import 'package:valuables/auth/auth_service.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_chat_core/flutter_chat_core.dart';
import 'package:flutter/foundation.dart';

class ChatClient {
  late final AuthService _authService;
  late final SupabaseClient _supabaseClient;
  late RealtimeChannel _channel;
  late List<Message> _messages;

  ChatClient() {
    _authService = GetIt.I<AuthService>();
    _supabaseClient = Supabase.instance.client;
  }

  Future<bool> sendMessage({
    required String text,
    required String roomId,
  }) async {
    final user = _authService.getCurrentUserSession()!.user;

    if (text.trim() == "") {
      throw Exception("chat_client: message can't be empty");
    }

    Map<String, dynamic> result = await _supabaseClient
        .from("chat_room_member")
        .select("member_id")
        .eq("chat_room_id", roomId)
        .eq("member_id", user.id)
        .single();

    if (result["member_id"] == null) {
      throw Exception("chat_client: user not a member of the chat");
    }

    try {
      await _supabaseClient.from("message").insert({
        "text": text.trim(),
        "chat_room_id": roomId,
        "author_id": user.id,
      });
    } catch (e) {
      rethrow;
    }
    return true;
  }

  RealtimeChannel useRealtimeChat({
    required String roomId,
    required String userId,
    required void Function(Map<String, dynamic> newRecord) onMessageReceived,
  }) {
    final token = _authService.getCurrentUserSession()!.accessToken;
    _supabaseClient.realtime.setAuth(token);

    // Initialize the channel
    _channel = _supabaseClient.channel(
      "room:$roomId:messages", // Removed the extra space after "room:"
      opts: const RealtimeChannelConfig(private: true),
    );

    _channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'message',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'chat_room_id',
            value: roomId,
          ), // Only listen to this specific room
          callback: (payload) {
            // Pass the newly inserted database row to the UI
            onMessageReceived(payload.newRecord);
          },
        )
        .subscribe((status, error) {
          if (status == RealtimeSubscribeStatus.subscribed) {
            debugPrint("Successfully subscribed to realtime chat.");
          }
        });

    return _channel;
  }

  void disconnect() {
    _channel.unsubscribe();
    _channel.untrack();
  }
}
