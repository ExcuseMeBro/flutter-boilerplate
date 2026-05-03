import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/core/storage/local_storage.dart';
import 'package:flutter_boilerplate/core/storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorage secureStorage,
    required LocalStorage localStorage,
    required Dio dio,
    required Uri refreshUri,
  })  : _secureStorage = secureStorage,
        _localStorage = localStorage,
        _dio = dio,
        _refreshUri = refreshUri;

  final SecureStorage _secureStorage;
  final LocalStorage _localStorage;
  final Dio _dio;
  final Uri _refreshUri;

  bool _isRefreshing = false;
  Completer<bool>? _refreshCompleter;

  static const retryExtraKey = '__retried_after_refresh__';
  static const skipAuthExtraKey = '__skip_auth__';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept-Language'] = _localStorage.getLocaleCode();

    if (options.extra[skipAuthExtraKey] == true) {
      handler.next(options);
      return;
    }

    final token = await _secureStorage.getAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[retryExtraKey] == true;
    final skipAuth = err.requestOptions.extra[skipAuthExtraKey] == true;

    if (!isUnauthorized || alreadyRetried || skipAuth) {
      handler.next(err);
      return;
    }

    final refreshed = await _refreshToken();
    if (!refreshed) {
      await Future.wait([
        _secureStorage.clearAuth(),
        _localStorage.clearAuth(),
      ]);
      handler.next(err);
      return;
    }

    try {
      final newToken = await _secureStorage.getAccessToken();
      final response = await _dio.fetch<dynamic>(
        err.requestOptions
          ..headers['Authorization'] = 'Bearer $newToken'
          ..extra[retryExtraKey] = true,
      );
      handler.resolve(response);
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  Future<bool> _refreshToken() async {
    if (_isRefreshing && _refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _isRefreshing = true;
    _refreshCompleter = Completer<bool>();

    try {
      final refreshToken = await _secureStorage.getRefreshToken();
      if (refreshToken == null || refreshToken.isEmpty) {
        _complete(false);
        return false;
      }

      final response = await Dio().postUri<Map<String, dynamic>>(
        _refreshUri,
        data: {'refresh': refreshToken},
        options: Options(
          headers: {'Accept': 'application/json'},
          sendTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
        ),
      );

      final data = response.data;
      final access = data?['access'] as String?;
      final refresh = data?['refresh'] as String?;

      if (access == null || access.isEmpty) {
        _complete(false);
        return false;
      }

      await Future.wait([
        _secureStorage.setAccessToken(access),
        _localStorage.setAccessToken(access),
        if (refresh != null && refresh.isNotEmpty) ...[
          _secureStorage.setRefreshToken(refresh),
          _localStorage.setRefreshToken(refresh),
        ],
      ]);

      _complete(true);
      return true;
    } catch (_) {
      _complete(false);
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void _complete(bool value) {
    if (_refreshCompleter?.isCompleted == false) {
      _refreshCompleter?.complete(value);
    }
    _refreshCompleter = null;
  }
}
