import 'package:flutter/foundation.dart';

class AppConfig {
  const AppConfig._();

  static const appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'Flutter Boilerplate',
  );

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.example.com',
  );

  static const apiVersion = String.fromEnvironment(
    'API_VERSION',
    defaultValue: 'v1',
  );

  static const requestTimeout = Duration(seconds: 25);

  static bool get isRelease => kReleaseMode;
  static bool get isDebug => kDebugMode;

  /// The documented placeholder host; release builds must override it.
  static const placeholderApiHost = 'api.example.com';

  /// Refuses to launch a release build pointed at a placeholder, malformed or
  /// non-HTTPS API base URL. Debug and test keep running with template defaults.
  static void validate({required String apiBaseUrl, required bool isRelease}) {
    if (!isRelease) return;

    final uri = Uri.tryParse(apiBaseUrl);
    final isAbsoluteHttps =
        uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
    if (!isAbsoluteHttps || uri.host == placeholderApiHost) {
      throw StateError(
        'API_BASE_URL must be an absolute HTTPS URL that is not the placeholder '
        '"$placeholderApiHost" in release builds (received: "$apiBaseUrl").',
      );
    }
  }
}
