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
  final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
      flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
  if (androidPlugin != null) {
    await androidPlugin.requestNotificationsPermission();
  }
}


Future<void> showMatchNotification({
  required String title,      // comes straight from notifications.title
  required String body,       // comes straight from notifications.body
  required String notificationId, // notifications.id — used for dedup
  required String foundItemId, 
  required double foundLat, 
  required double foundLng,
}) async {
  int notifIntId = int.parse(notificationId.replaceAll('-', '').substring(0, 8), radix: 16);
  await flutterLocalNotificationsPlugin.show(
    notifIntId, // Unique integer ID for the notification (derived from the UUID)
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
    payload: '$foundLat,$foundLng,$foundItemId,$notificationId' // Pass lat,lng,itemId as payload for navigation on tap
  );
}