import 'package:valuables/auth/auth_service.dart';
import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatClient {
  late final _authService;
  late final _supabaseClient;
  ChatClient() {
    _authService = GetIt.I<AuthService>();
    _supabaseClient = Supabase.instance.client;
  }

  Future<bool> sendMessage({
    required String text,
    required String roomId,
  }) async {
    final user = _authService.getCurrentUserSession()!.user;

    if (user == null) {
      throw Exception("chat_client: login first");
    }

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
}
