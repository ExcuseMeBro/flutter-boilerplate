import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/app/app.dart';
import 'package:flutter_boilerplate/core/config/app_config.dart';
import 'package:flutter_boilerplate/core/storage/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.validate(
    apiBaseUrl: AppConfig.apiBaseUrl,
    isRelease: AppConfig.isRelease,
  );
  runApp(
    ProviderScope(
      overrides: [secureStorageProvider.overrideWithValue(SecureStorage())],
      child: const StarterApp(),
    ),
  );
}
