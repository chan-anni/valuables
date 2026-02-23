import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/auth/auth_service.dart';

class ChatService {
  final _supabaseClient = Supabase.instance.client;
  final authService = AuthService();

  Future<Map<String, dynamic>?> createRoom(String name) async {
    try {
      if (name.isEmpty) return null;

      final data = await _supabaseClient
          .from('chat_room')
          .insert({
            'name': name, // Using the variable from controller
            'is_public': false,
          })
          .select('id')
          .single();

      return data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> addUserToRoom(User user, String roomId) async {
    return await _supabaseClient.from("chat_room_member").insert({
      "chat_room_id": roomId,
      "member_id": user.id,
    });
  }
}
