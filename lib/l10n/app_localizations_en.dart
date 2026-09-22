// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Flutter Boilerplate';

  @override
  String get homeHeadline => 'Production Flutter starter';

  @override
  String get homeSubtitle =>
      'Riverpod, GoRouter, Dio, secure storage, Firebase-ready bootstrap.';

  @override
  String get homeApiBaseUrl => 'API base URL';

  @override
  String get homeFirebase => 'Firebase';

  @override
  String get homeOpenSettings => 'Open settings';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsEnvironment => 'Environment';

  @override
  String get settingsApi => 'API';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsCheckFcmToken => 'Check FCM token';

  @override
  String get settingsEnableNotifications => 'Enable notifications';

  @override
  String get firebaseLoading => 'Checking…';

  @override
  String get firebaseConfigured => 'Configured';

  @override
  String get firebaseNotConfigured => 'Not configured yet';

  @override
  String get firebaseReady => 'ready';

  @override
  String get firebaseUnconfigured => 'not configured';

  @override
  String get environmentRelease => 'release';

  @override
  String get environmentDebug => 'debug';

  @override
  String get localeEnglish => 'English';

  @override
  String get localeUzbek => 'Uzbek';

  @override
  String get localeRussian => 'Russian';

  @override
  String get fcmTokenUnavailable => 'FCM token unavailable.';

  @override
  String get fcmTokenCopied => 'FCM token copied from service.';

  @override
  String get notificationsEnabled => 'Notifications enabled.';

  @override
  String get notificationsDenied => 'Notification permission was denied.';

  @override
  String get notificationsUnavailable =>
      'Notification permission is unavailable on this device.';
}
