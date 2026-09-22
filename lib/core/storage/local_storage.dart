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

/// One-time startup housekeeping: promote any legacy locale into the async
/// store and erase plaintext tokens from both stores. The locale controller
/// awaits this provider, so migration and purge cannot race each other.
final startupMaintenanceProvider = FutureProvider<void>((ref) async {
  final storage = ref.watch(localStorageProvider);
  await storage.migrateLegacyLocale();
  await storage.purgeLegacyTokens();
});

/// Non-sensitive preferences only. Auth tokens live in `SecureStorage`;
/// SharedPreferences is plaintext on disk and readable on a rooted device.
///
/// `SharedPreferencesAsync` is the active store. Installs created before the
/// async migration may still hold a locale and plaintext tokens in the legacy
/// `SharedPreferences` backend, which this class reads once and cleans up.
class LocalStorage implements LocaleStore {
  LocalStorage(
    this._async, {
    Future<SharedPreferences> Function()? legacyPreferences,
  }) : _legacyPreferences = legacyPreferences ?? SharedPreferences.getInstance;

  final SharedPreferencesAsync _async;
  final Future<SharedPreferences> Function() _legacyPreferences;

  SharedPreferences? _legacy;

  static const _localeKey = '${AppConfig.appName}.locale';

  /// Written by app versions that mirrored tokens into plaintext prefs.
  static const _legacyAccessTokenKey = '${AppConfig.appName}.accessToken';
  static const _legacyRefreshTokenKey = '${AppConfig.appName}.refreshToken';

  Future<SharedPreferences> _legacyStore() async =>
      _legacy ??= await _legacyPreferences();

  @override
  Future<String?> readLocaleCode() async {
    final current = await _async.getString(_localeKey);
    if (current != null && current.isNotEmpty) return current;
    return migrateLegacyLocale();
  }

  /// Promotes a legacy locale into the async store only when async has none.
  Future<String?> migrateLegacyLocale() async {
    final legacyCode = (await _legacyStore()).getString(_localeKey);
    if (legacyCode == null || legacyCode.isEmpty) return null;
    await _async.setString(_localeKey, legacyCode);
    return legacyCode;
  }

  @override
  Future<void> writeLocaleCode(String code) =>
      _async.setString(_localeKey, code);

  /// Erases tokens leaked into plaintext prefs by earlier builds, from both the
  /// active async store and the legacy store. Safe to call on every launch;
  /// remove once no installs predate this version.
  Future<void> purgeLegacyTokens() async {
    final legacy = await _legacyStore();
    await Future.wait([
      _async.remove(_legacyAccessTokenKey),
      _async.remove(_legacyRefreshTokenKey),
      legacy.remove(_legacyAccessTokenKey),
      legacy.remove(_legacyRefreshTokenKey),
    ]);
  }
}
