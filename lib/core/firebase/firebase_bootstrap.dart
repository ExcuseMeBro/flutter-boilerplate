import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_boilerplate/core/firebase/push_notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final firebaseStatusProvider = Provider<FirebaseStatus>((ref) {
  return const FirebaseStatus.unconfigured();
});

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    return;
  }
}

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<FirebaseStatus> initialize() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await PushNotificationService.initialize();
      return const FirebaseStatus.configured();
    } catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Firebase disabled: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
      return FirebaseStatus.unconfigured(error.toString());
    }
  }
}

class FirebaseStatus {
  const FirebaseStatus._({
    required this.isConfigured,
    this.error,
  });

  const FirebaseStatus.configured() : this._(isConfigured: true);

  const FirebaseStatus.unconfigured([String? error])
    : this._(isConfigured: false, error: error);

  final bool isConfigured;
  final String? error;
}
