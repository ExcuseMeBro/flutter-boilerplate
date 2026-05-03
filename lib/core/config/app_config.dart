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
}
