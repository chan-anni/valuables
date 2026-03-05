import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_notifs.dart';
import 'package:flutter/src/foundation/print.dart';


class MatchService {
  static RealtimeChannel? _channel;

  static void listenForMatches() {
    debugPrintSynchronously('Listening for matches...'); 
    final userId = Supabase.instance.client.auth.currentUser?.id;
    debugPrintSynchronously('userId: $userId'); 
    if (userId == null) return;

    _channel = Supabase.instance.client
    .channel('notifications:$userId')
    .onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) async {
        debugPrint('🔔 Notification received: ${payload.newRecord}'); // 👈
        final row = payload.newRecord;
        final data = row['data'] as Map<String, dynamic>? ?? {};
        final lostItemId = data['lost_item_id'] as String? ?? '';

        await showMatchNotification(
          title: row['title'] as String,
          body: row['body'] as String,
          notificationId: row['id'] as String,
          lostItemId: lostItemId,
        );

        await Supabase.instance.client
            .from('notifications')
            .update({'is_read': true})
            .eq('id', row['id']);
      },
    )
    .subscribe((status, [error]) {
      debugPrint('📡 Realtime status: $status error: $error'); // 👈
    });
  }

  static void dispose() {
    _channel?.unsubscribe();
  }
}