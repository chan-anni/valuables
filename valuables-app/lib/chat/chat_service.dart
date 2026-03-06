import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/auth/auth_service.dart';

class ChatService {
  final _supabaseClient = Supabase.instance.client;
  final authService = GetIt.I<AuthService>();

  Future<Map<String, dynamic>?> createRoom({
    required String name,
    required String itemId,
  }) async {
    try {
      if (name.isEmpty) return null;

      final data = await _supabaseClient
          .from('chat_room')
          .insert({
            'name': name, // Using the variable from controller
            'is_public': false,
            'item_id': itemId,
          })
          .select('id')
          .single();

      return data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> addUsersToRoom(List<String> userIds, String roomId) async {
    try {
      // 1. Transform the list of User objects into a list of Maps
      final List<Map<String, dynamic>> inserts = userIds
          .map((userId) => {"chat_room_id": roomId, "member_id": userId})
          .toList();

      // 2. Perform a bulk insert
      await _supabaseClient.from("chat_room_member").insert(inserts);
    } catch (e) {
      rethrow; // Pass the error up to the UI to show a snackbar
    }
  }

  Future<Map<String, dynamic>?> getRoom(String roomId) async {
    final user = authService.getCurrentUserSession()!.user;
    try {
      final result = await _supabaseClient
          .from("chat_room")
          .select("id, name, items(image_url), chat_room_member!inner ()")
          .eq("id", roomId)
          .eq("chat_room_member.member_id", user.id)
          .single();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUser() async {
    final user = authService.getCurrentUserSession()!.user;
    try {
      final result = await _supabaseClient
          .from("users")
          .select("id, username, profile_pic_url")
          .eq("id", user.id)
          .single();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>?>> getMessages(String roomId) async {
    try {
      final result = await _supabaseClient
          .from("message")
          .select(
            "id, text, created_at, author_id, author:users (username, profile_pic_url)",
          )
          .eq("chat_room_id", roomId)
          .order("created_at", ascending: false)
          .limit(100);

      return result;
    } catch (e) {
      rethrow;
    }
  }
}
