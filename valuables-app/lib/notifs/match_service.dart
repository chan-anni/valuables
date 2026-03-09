import 'package:supabase_flutter/supabase_flutter.dart';
import 'local_notifs.dart';


class MatchService {
  static RealtimeChannel? _channel;

  static void listenForMatches() {

    final userId = Supabase.instance.client.auth.currentUser?.id;
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
        final row = payload.newRecord;
        final data = row['data'] as Map<String, dynamic>? ?? {};
        final foundItemId = data['found_item_id'] as String? ?? '';
        final foundLat = (data['found_lat'] as num?)?.toDouble() ?? 0.0;
        final foundLng = (data['found_lng'] as num?)?.toDouble() ?? 0.0;

        await showMatchNotification(
          title: row['title'] as String,
          body: row['body'] as String,
          notificationId: row['id'] as String,
          foundItemId: foundItemId,
          foundLat: foundLat,
          foundLng: foundLng,
        );

      
      },
    )
    .subscribe((status, [error]) {
    });
  }

  static void dispose() {
    _channel?.unsubscribe();
  }
}