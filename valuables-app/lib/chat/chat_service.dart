import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:valuables/auth/auth_service.dart';

class ChatService {
  final _supabaseClient = Supabase.instance.client;
  final authService = GetIt.I<AuthService>();

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
}
