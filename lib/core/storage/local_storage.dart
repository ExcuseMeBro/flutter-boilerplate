import 'package:flutter_boilerplate/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main().');
});

final localStorageProvider = Provider<LocalStorage>((ref) {
  return LocalStorage(ref.watch(sharedPreferencesProvider));
});

class LocalStorage {
  LocalStorage(this._prefs);

  final SharedPreferences _prefs;

  static const _accessTokenKey = '${AppConfig.appName}.accessToken';
  static const _refreshTokenKey = '${AppConfig.appName}.refreshToken';
  static const _localeKey = '${AppConfig.appName}.locale';

  Future<void> setAccessToken(String token) => _prefs.setString(_accessTokenKey, token);

  String? getAccessToken() => _prefs.getString(_accessTokenKey);

  Future<void> setRefreshToken(String token) => _prefs.setString(_refreshTokenKey, token);

  String? getRefreshToken() => _prefs.getString(_refreshTokenKey);

  Future<void> clearAuth() async {
    await Future.wait([
      _prefs.remove(_accessTokenKey),
      _prefs.remove(_refreshTokenKey),
    ]);
  }

  Future<void> setLocaleCode(String code) => _prefs.setString(_localeKey, code);

  String getLocaleCode() => _prefs.getString(_localeKey) ?? 'en';
}
