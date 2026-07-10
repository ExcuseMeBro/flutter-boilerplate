import 'package:flutter_boilerplate/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main().');
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage(ref.watch(sharedPreferencesProvider));
});

/// Non-sensitive preferences only. Auth tokens live in [SecureStorage];
/// SharedPreferences is plaintext on disk and readable on a rooted device.
class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _localeKey = '${AppConfig.appName}.locale';

  /// Written by app versions that mirrored tokens into plaintext prefs.
  static const _legacyAccessTokenKey = '${AppConfig.appName}.accessToken';
  static const _legacyRefreshTokenKey = '${AppConfig.appName}.refreshToken';

  Future<void> setLocaleCode(String code) => _prefs.setString(_localeKey, code);

  String getLocaleCode() => _prefs.getString(_localeKey) ?? 'en';

  /// Erases tokens leaked into prefs by earlier builds. Safe to call on every
  /// launch; remove once no installs predate this version.
  Future<void> purgeLegacyTokens() async {
    await Future.wait([
      _prefs.remove(_legacyAccessTokenKey),
      _prefs.remove(_legacyRefreshTokenKey),
    ]);
  }
}
