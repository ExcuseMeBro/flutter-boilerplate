import 'package:flutter_boilerplate/core/config/app_config.dart';
import 'package:flutter_boilerplate/core/localization/locale_store.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Asynchronous preferences. Constructed directly; no startup override needed
/// so `main` never awaits storage before `runApp`.
final sharedPreferencesAsyncProvider = Provider<SharedPreferencesAsync>(
  (ref) => SharedPreferencesAsync(),
);

final localStorageProvider = Provider<LocalStorage>(
  (ref) => LocalStorage(ref.watch(sharedPreferencesAsyncProvider)),
);

/// Erases legacy plaintext tokens once the first frame is up.
final legacyTokenPurgeProvider = FutureProvider<void>(
  (ref) => ref.watch(localStorageProvider).purgeLegacyTokens(),
);

/// Non-sensitive preferences only. Auth tokens live in `SecureStorage`;
/// SharedPreferences is plaintext on disk and readable on a rooted device.
class LocalStorage implements LocaleStore {
  LocalStorage(this._prefs);

  final SharedPreferencesAsync _prefs;

  static const _localeKey = '${AppConfig.appName}.locale';

  /// Written by app versions that mirrored tokens into plaintext prefs.
  static const _legacyAccessTokenKey = '${AppConfig.appName}.accessToken';
  static const _legacyRefreshTokenKey = '${AppConfig.appName}.refreshToken';

  @override
  Future<String?> readLocaleCode() => _prefs.getString(_localeKey);

  @override
  Future<void> writeLocaleCode(String code) =>
      _prefs.setString(_localeKey, code);

  /// Erases tokens leaked into prefs by earlier builds. Safe to call on every
  /// launch; remove once no installs predate this version.
  Future<void> purgeLegacyTokens() async {
    await Future.wait([
      _prefs.remove(_legacyAccessTokenKey),
      _prefs.remove(_legacyRefreshTokenKey),
    ]);
  }
}
