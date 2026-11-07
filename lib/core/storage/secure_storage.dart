import 'package:flutter_boilerplate/core/storage/coalesced_read.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

final secureStorageProvider = Provider<SecureStorage>((ref) {
  throw UnimplementedError('SecureStorage must be overridden in main().');
});

class SecureStorage {
  SecureStorage({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
            ),
          );

  final FlutterSecureStorage _storage;
  late final _access = CoalescedRead(() => _storage.read(key: _accessTokenKey));
  late final _refresh = CoalescedRead(
    () => _storage.read(key: _refreshTokenKey),
  );

  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';

  Future<String?> getAccessToken() => _access.read();

  Future<void> setAccessToken(String token) =>
      _access.write(() => _storage.write(key: _accessTokenKey, value: token));

  Future<String?> getRefreshToken() => _refresh.read();

  Future<void> setRefreshToken(String token) =>
      _refresh.write(() => _storage.write(key: _refreshTokenKey, value: token));

  Future<void> clearAuth() async {
    await Future.wait([
      _access.write(() => _storage.delete(key: _accessTokenKey)),
      _refresh.write(() => _storage.delete(key: _refreshTokenKey)),
    ]);
  }
}
