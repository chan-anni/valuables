import 'package:flutter/material.dart';
import 'package:valuables/screens/map_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<NotifTarget?> notifTargetNotifier = ValueNotifier(null);

class NotifTarget {
  final double lat;
  final double lng;
  final String itemId;
  NotifTarget(this.lat, this.lng, this.itemId);
}

void handleNotificationTap(String? payload) {
  if (payload == null) return;

  final parts = payload.split(',');
  if (parts.length < 3) return;

  final double? lat = double.tryParse(parts[0]);
  final double? lng = double.tryParse(parts[1]);
  final String itemId = parts[2].trim();

  if (lat == null || lng == null) return;
  debugPrint('📍 lat: $lat, lng: $lng, itemId: $itemId');
  notifTargetNotifier.value = NotifTarget(lat, lng, itemId);

  // Pushing another MapPage ontop of whatever the user is currently on (home, messages, or even another map) 
  // to show the matched item from the notification. Inclues information in the MapPage constructor to highlight/zoom to
  // the correct marker.
  Future.delayed(const Duration(milliseconds: 500), () {
    navigatorKey.currentState?.push( 
      MaterialPageRoute(
        builder: (_) => MapPage(
          notifItemLat: lat,
          notifItemLang: lng,
          notifItemId: itemId,
          fromNotification: true,
        ),
      ),
    );
  });
}