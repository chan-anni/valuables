import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void handleNotificationTap(String? payload) {
  
  if (payload == null) return;
  // payload = lost_item_id
  // swap Placeholder() for your item detail screen when ready
  navigatorKey.currentState?.push(
    MaterialPageRoute(
      builder: (_) => const Placeholder(),
    ),
  );
}