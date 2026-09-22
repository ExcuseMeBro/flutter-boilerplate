// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'Flutter Boilerplate';

  @override
  String get homeHeadline => 'Ishlab chiqarishga tayyor Flutter shabloni';

  @override
  String get homeSubtitle =>
      'Riverpod, GoRouter, Dio, xavfsiz saqlash, Firebase-ga tayyor bootstrap.';

  @override
  String get homeApiBaseUrl => 'API manzili';

  @override
  String get homeFirebase => 'Firebase';

  @override
  String get homeOpenSettings => 'Sozlamalarni ochish';

  @override
  String get settingsTitle => 'Sozlamalar';

  @override
  String get settingsEnvironment => 'Muhit';

  @override
  String get settingsApi => 'API';

  @override
  String get settingsLanguage => 'Til';

  @override
  String get settingsCheckFcmToken => 'FCM tokenni tekshirish';

  @override
  String get settingsEnableNotifications => 'Bildirishnomalarni yoqish';

  @override
  String get firebaseLoading => 'Tekshirilmoqda…';

  @override
  String get firebaseConfigured => 'Sozlangan';

  @override
  String get firebaseNotConfigured => 'Hali sozlanmagan';

  @override
  String get firebaseReady => 'tayyor';

  @override
  String get firebaseUnconfigured => 'sozlanmagan';

  @override
  String get environmentRelease => 'release';

  @override
  String get environmentDebug => 'debug';

  @override
  String get localeEnglish => 'Inglizcha';

  @override
  String get localeUzbek => 'Oʻzbekcha';

  @override
  String get localeRussian => 'Ruscha';

  @override
  String get fcmTokenUnavailable => 'FCM token mavjud emas.';

  @override
  String get fcmTokenCopied => 'FCM token xizmatdan olindi.';

  @override
  String get notificationsEnabled => 'Bildirishnomalar yoqildi.';

  @override
  String get notificationsDenied => 'Bildirishnoma ruxsati rad etildi.';

  @override
  String get notificationsUnavailable =>
      'Bu qurilmada bildirishnoma ruxsati mavjud emas.';
}
