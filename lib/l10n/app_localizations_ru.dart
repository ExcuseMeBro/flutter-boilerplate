// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Flutter Boilerplate';

  @override
  String get homeHeadline => 'Готовый к продакшену Flutter-шаблон';

  @override
  String get homeSubtitle =>
      'Riverpod, GoRouter, Dio, безопасное хранилище, bootstrap с поддержкой Firebase.';

  @override
  String get homeApiBaseUrl => 'Базовый URL API';

  @override
  String get homeFirebase => 'Firebase';

  @override
  String get homeOpenSettings => 'Открыть настройки';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get settingsEnvironment => 'Среда';

  @override
  String get settingsApi => 'API';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsCheckFcmToken => 'Проверить FCM-токен';

  @override
  String get settingsEnableNotifications => 'Включить уведомления';

  @override
  String get firebaseLoading => 'Проверка…';

  @override
  String get firebaseConfigured => 'Настроено';

  @override
  String get firebaseNotConfigured => 'Ещё не настроено';

  @override
  String get firebaseReady => 'готово';

  @override
  String get firebaseUnconfigured => 'не настроено';

  @override
  String get environmentRelease => 'release';

  @override
  String get environmentDebug => 'debug';

  @override
  String get localeEnglish => 'Английский';

  @override
  String get localeUzbek => 'Узбекский';

  @override
  String get localeRussian => 'Русский';

  @override
  String get fcmTokenUnavailable => 'FCM-токен недоступен.';

  @override
  String get fcmTokenCopied => 'FCM-токен скопирован в буфер обмена.';

  @override
  String get notificationsEnabled => 'Уведомления включены.';

  @override
  String get notificationsDenied => 'В разрешении на уведомления отказано.';

  @override
  String get notificationsUnavailable =>
      'Разрешение на уведомления недоступно на этом устройстве.';
}
