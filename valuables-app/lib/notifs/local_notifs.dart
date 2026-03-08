import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'notif_handler.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> setupNotifications() async {
  const AndroidInitializationSettings androidSettings =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
    requestAlertPermission: true,
    requestBadgePermission: true,
    requestSoundPermission: true,
  );

  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(android: androidSettings, iOS: iosSettings),
    onDidReceiveNotificationResponse: (response) {
      handleNotificationTap(response.payload);
    },
  );
}

Future<void> showMatchNotification({
  required String title,      // comes straight from notifications.title
  required String body,       // comes straight from notifications.body
  required String notificationId, // notifications.id — used for dedup
  required String lostItemId, // notifications.data.lost_item_id — used as nav payload
  required double foundLat, 
  required double foundLng,
}) async {
  await flutterLocalNotificationsPlugin.show(
    notificationId.hashCode,
    title,
    body,
    // iOS and Android notification to ask about notification details like sound, badge, priority, etc.
    const NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBadge: true,
      ),
      android: AndroidNotificationDetails(
        'matches_channel',
        'Item Matches',
        channelDescription: 'Alerts when a found item matches your lost report',
        importance: Importance.high,
        priority: Priority.high,
      ),
    ),
    payload: '$foundLat,$foundLng,$lostItemId', // Pass lat,lng,itemId as payload for navigation on tap
  );
}