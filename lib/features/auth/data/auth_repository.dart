import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/core/network/api_client.dart';
import 'package:flutter_boilerplate/core/network/auth_interceptor.dart';
import 'package:flutter_boilerplate/core/network/network_providers.dart';
import 'package:flutter_boilerplate/core/storage/local_storage.dart';
import 'package:flutter_boilerplate/core/storage/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    client: ref.watch(apiClientProvider),
    localStorage: ref.watch(localStorageProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
});

class AuthRepository {
  AuthRepository({
    required ApiClient client,
    required LocalStorage localStorage,
    required SecureStorage secureStorage,
  })  : _client = client,
        _localStorage = localStorage,
        _secureStorage = secureStorage;

  final ApiClient _client;
  final LocalStorage _localStorage;
  final SecureStorage _secureStorage;

  Future<void> login({
    required String phone,
    required String password,
  }) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login/',
      data: {
        'phone': phone,
        'password': password,
      },
      options: Options(extra: {AuthInterceptor.skipAuthExtraKey: true}),
    );

    final access = response['access'] as String?;
    final refresh = response['refresh'] as String?;

    if (access == null || refresh == null) {
      throw const FormatException('Auth response missing tokens.');
    }

    await Future.wait([
      _secureStorage.setAccessToken(access),
      _secureStorage.setRefreshToken(refresh),
      _localStorage.setAccessToken(access),
      _localStorage.setRefreshToken(refresh),
    ]);
  }

  Future<void> logout() async {
    await Future.wait([
      _secureStorage.clearAuth(),
      _localStorage.clearAuth(),
    ]);
  }
}
