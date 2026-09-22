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

  /// Plugin setup without any permission prompt. Overrideable for unit tests
  /// so the real `initialize` ordering can be verified without a device.
  @visibleForTesting
  static Future<void> Function() initializePlatform = _initializePlatform;

  /// Overrideable in tests; returns the platform authorization result.
  @visibleForTesting
  static Future<NotificationSettings> Function() permissionRequester =
      _requestPlatformPermission;

  /// Overrideable in tests; resolves the current FCM token.
  @visibleForTesting
  static Future<String?> Function() tokenProvider = _getPlatformToken;

  @visibleForTesting
  static void resetTestSeams() {
    initializePlatform = _initializePlatform;
    permissionRequester = _requestPlatformPermission;
    tokenProvider = _getPlatformToken;
  }

  /// Registers the foreground listener and notification channel. Permission is
  /// deliberately NOT requested here; Settings asks for it explicitly.
  static Future<void> initialize() async {
    if (kIsWeb) return;
    await initializePlatform();
  }

  static Future<NotificationSettings> requestPermission() {
    return permissionRequester();
  }

  static Future<String?> getToken() => tokenProvider();

  static Future<String?> _getPlatformToken() {
    if (kIsWeb) return Future<String?>.value();
    return FirebaseMessaging.instance.getToken();
  }

  static Future<void> _initializePlatform() async {
    await _localNotifications.initialize(
      settings: buildInitializationSettings(),
    );

    if (defaultTargetPlatform == TargetPlatform.android) {
      await _localNotifications
          .resolvePlatformSpecificImplementation<local.AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(_defaultChannel);
    }

    FirebaseMessaging.onMessage.listen(_showForegroundNotification);
  }

  /// Platform initialization settings shared with tests.
  ///
  /// Darwin permission flags are explicitly false: plugin initialization must
  /// never prompt. Notification permission is requested only by
  /// [requestPermission] from the Settings action.
  @visibleForTesting
  static local.InitializationSettings buildInitializationSettings() {
    const darwin = local.DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    return const local.InitializationSettings(
      android: local.AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: darwin,
      macOS: darwin,
    );
  }

  static Future<NotificationSettings> _requestPlatformPermission() {
    return FirebaseMessaging.instance.requestPermission();
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
