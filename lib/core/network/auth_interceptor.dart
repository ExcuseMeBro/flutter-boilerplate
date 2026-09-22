import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/core/localization/locale_controller.dart';
import 'package:flutter_boilerplate/core/storage/local_storage.dart';
import 'package:flutter_boilerplate/core/storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required SecureStorage secureStorage,
    required LocalStorage localStorage,
    required Dio dio,
    required Uri refreshUri,
    Dio? refreshClient,
    void Function()? onAuthFailure,
  })  : _secureStorage = secureStorage,
        _localStorage = localStorage,
        _dio = dio,
        _refreshUri = refreshUri,
        _refreshClient = refreshClient ?? Dio(),
        _onAuthFailure = onAuthFailure {
    // A refresh that hangs would stall every queued 401 behind it.
    _refreshClient.options
      ..connectTimeout ??= _refreshTimeout
      ..sendTimeout ??= _refreshTimeout
      ..receiveTimeout ??= _refreshTimeout;
  }

  final SecureStorage _secureStorage;
  final LocalStorage _localStorage;
  final Dio _dio;
  final Uri _refreshUri;

  /// Kept separate from [_dio] so the refresh call never re-enters this
  /// interceptor and cannot recurse on its own 401.
  final Dio _refreshClient;

  final void Function()? _onAuthFailure;

  /// Non-null exactly while a refresh is in flight; every concurrent 401
  /// awaits this instead of spending the refresh token again.
  Completer<bool>? _refresh;

  static const retryExtraKey = '__retried_after_refresh__';
  static const skipAuthExtraKey = '__skip_auth__';

  static const _refreshTimeout = Duration(seconds: 15);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    options.headers['Accept-Language'] =
        (await resolveActiveLocale(_localStorage)).languageCode;

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

    // A concurrent refresh may have already rotated the token while this
    // request was in flight; replay it before spending another refresh token.
    final currentToken = await _secureStorage.getAccessToken();
    final sentToken = _bearerOf(err.requestOptions);
    if (currentToken != null &&
        currentToken.isNotEmpty &&
        currentToken != sentToken) {
      await _replay(err, currentToken, handler);
      return;
    }

    final refreshed = await _refreshToken();
    if (!refreshed) {
      await _secureStorage.clearAuth();
      _onAuthFailure?.call();
      handler.next(err);
      return;
    }

    final newToken = await _secureStorage.getAccessToken();
    await _replay(err, newToken, handler);
  }

  /// Re-sends the failed request once, with [token] and a replayable body.
  Future<void> _replay(
    DioException err,
    String? token,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions
      ..headers['Authorization'] = 'Bearer $token'
      ..extra[retryExtraKey] = true;

    // A finalized FormData stream cannot be read twice.
    final data = options.data;
    if (data is FormData) {
      options.data = data.clone();
    }

    try {
      handler.resolve(await _dio.fetch<dynamic>(options));
    } on DioException catch (retryError) {
      handler.next(retryError);
    }
  }

  String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is! String || !header.startsWith('Bearer ')) return null;
    return header.substring('Bearer '.length);
  }

  Future<bool> _refreshToken() {
    final inFlight = _refresh;
    if (inFlight != null) return inFlight.future;

    final completer = Completer<bool>();
    _refresh = completer;

    _performRefresh().then((success) {
      _refresh = null;
      completer.complete(success);
    }).catchError((Object _) {
      _refresh = null;
      completer.complete(false);
    });

    return completer.future;
  }

  Future<bool> _performRefresh() async {
    final refreshToken = await _secureStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await _refreshClient.postUri<Map<String, dynamic>>(
        _refreshUri,
        data: {'refresh': refreshToken},
        options: Options(headers: const {'Accept': 'application/json'}),
      );

      final data = response.data;
      final access = data?['access'] as String?;
      final refresh = data?['refresh'] as String?;

      if (access == null || access.isEmpty) return false;

      await _secureStorage.setAccessToken(access);
      if (refresh != null && refresh.isNotEmpty) {
        await _secureStorage.setRefreshToken(refresh);
      }
      return true;
    } on DioException {
      return false;
    }
  }
}
