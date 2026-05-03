import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as local;

class PushNotificationService {
  const PushNotificationService._();

  static final local.FlutterLocalNotificationsPlugin _localNotifications =
      local.FlutterLocalNotificationsPlugin();

  static const local.AndroidNotificationChannel _defaultChannel = local.AndroidNotificationChannel(
    'default_channel',
    'Default notifications',
    description: 'General app notifications.',
    importance: local.Importance.high,
  );

  static Future<void> initialize() async {
    if (kIsWeb) return;

    const initializationSettings = local.InitializationSettings(
      android: local.AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: local.DarwinInitializationSettings(),
      macOS: local.DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(settings: initializationSettings);

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<local.AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_defaultChannel);
    }

    await FirebaseMessaging.instance.requestPermission(provisional: true);
    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  static Future<String?> getToken() async {
    if (kIsWeb) return null;
    return FirebaseMessaging.instance.getToken();
  }

  static Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final android = notification?.android;

    if (notification == null) return;

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: local.NotificationDetails(
        android: android == null
            ? null
            : local.AndroidNotificationDetails(
                _defaultChannel.id,
                _defaultChannel.name,
                channelDescription: _defaultChannel.description,
                icon: android.smallIcon,
                importance: local.Importance.high,
                priority: local.Priority.high,
              ),
        iOS: const local.DarwinNotificationDetails(),
        macOS: const local.DarwinNotificationDetails(),
      ),
    );
  }
}
