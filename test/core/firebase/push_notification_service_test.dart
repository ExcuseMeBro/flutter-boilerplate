import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_boilerplate/core/firebase/push_notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/notification_settings.dart';

void main() {
  tearDown(PushNotificationService.resetTestSeams);

  test('initialize configures plugins without requesting permission', () async {
    var platformInitializations = 0;
    var permissionRequests = 0;

    PushNotificationService.initializePlatform = () async {
      platformInitializations++;
    };
    PushNotificationService.permissionRequester = () async {
      permissionRequests++;
      return notificationSettings(AuthorizationStatus.authorized);
    };

    await PushNotificationService.initialize();

    expect(platformInitializations, 1);
    expect(permissionRequests, 0,
        reason: 'startup must not prompt for notification permission');

    final result = await PushNotificationService.requestPermission();

    expect(permissionRequests, 1);
    expect(result.authorizationStatus, AuthorizationStatus.authorized);
  });

  test('Darwin startup settings never request permissions', () {
    final settings = PushNotificationService.buildInitializationSettings();

    for (final darwin in [settings.iOS, settings.macOS]) {
      expect(darwin, isNotNull);
      expect(darwin!.requestAlertPermission, isFalse);
      expect(darwin.requestBadgePermission, isFalse);
      expect(darwin.requestSoundPermission, isFalse);
    }
  });
}
