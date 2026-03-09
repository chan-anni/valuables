import 'package:flutter/material.dart';
import 'package:valuables/screens/map_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class NotifTarget {
  final double lat;
  final double lng;
  final String itemId;
  NotifTarget(this.lat, this.lng, this.itemId);
}

Future<void> handleNotificationTap(String? payload) async {
  if (payload == null) return;

  final parts = payload.split(',');
  if (parts.length < 4) return;

  final double? lat = double.tryParse(parts[0]);
  final double? lng = double.tryParse(parts[1]);
  final String itemId = parts[2].trim();
  final String notificationId = parts[3].trim();

  if (lat == null || lng == null) return;

  await Supabase.instance.client
      .from('notifications')
      .update({'is_read': true})
      .eq('id', notificationId);

  // Pushing another MapPage ontop of whatever the user is currently on (home, messages, or even another map) 
  // to show the matched item arom the notification. Inclues information in the MapPage constructor to highlight/zoom to
  // the correct marker.
  Future.delayed(const Duration(milliseconds: 500), () {
    navigatorKey.currentState?.push( 
      MaterialPageRoute(
        builder: (_) => MapPage(
          notifItemLat: lat,
          notifItemLng: lng,
          notifItemId: itemId,
          fromNotification: true,
        ),
      ),
    );
  });
}