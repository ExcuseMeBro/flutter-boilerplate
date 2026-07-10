import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_boilerplate/core/config/app_config.dart';
import 'package:flutter_boilerplate/core/network/api_exception.dart';
import 'package:flutter_boilerplate/core/network/auth_interceptor.dart';
import 'package:flutter_boilerplate/core/network/pretty_log_interceptor.dart';
import 'package:flutter_boilerplate/core/storage/local_storage.dart';
import 'package:flutter_boilerplate/core/storage/secure_storage.dart';

class ApiClient {
  ApiClient({
    required LocalStorage localStorage,
    required SecureStorage secureStorage,
    Dio? dio,
    void Function()? onAuthFailure,
  }) : _dio = dio ?? Dio() {
    _dio.options = BaseOptions(
      baseUrl: _baseUri.toString(),
      connectTimeout: AppConfig.requestTimeout,
      receiveTimeout: AppConfig.requestTimeout,
      sendTimeout: AppConfig.requestTimeout,
      headers: const {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    );

    _dio.interceptors.addAll([
      AuthInterceptor(
        secureStorage: secureStorage,
        localStorage: localStorage,
        dio: _dio,
        refreshUri: refreshUri,
        onAuthFailure: onAuthFailure,
      ),
      if (kDebugMode) PrettyLogInterceptor(),
    ]);
  }

  final Dio _dio;

  static Uri get _baseUri {
    final normalizedBase = AppConfig.apiBaseUrl.endsWith('/')
        ? AppConfig.apiBaseUrl
        : '${AppConfig.apiBaseUrl}/';
    return Uri.parse(normalizedBase).resolve('${AppConfig.apiVersion}/');
  }

  /// Relative on purpose: a leading slash would resolve to the host root and
  /// drop the `/<apiVersion>` prefix.
  @visibleForTesting
  static Uri get refreshUri => _baseUri.resolve('auth/refresh/');

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _guard(
      () => _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> post<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _guard(
      () => _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> put<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _guard(
      () => _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> patch<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _guard(
      () => _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> delete<T>(
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return _guard(
      () => _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      ),
    );
  }

  Future<T> upload<T>(
    String path, {
    required FormData formData,
    ProgressCallback? onSendProgress,
    CancelToken? cancelToken,
  }) async {
    return _guard(
      () => _dio.post<T>(
        path,
        data: formData,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        options: Options(contentType: 'multipart/form-data'),
      ),
    );
  }

  Future<T> _guard<T>(Future<Response<T>> Function() request) async {
    try {
      final response = await request();
      return response.data as T;
    } on DioException catch (error) {
      throw ApiException.fromDio(error);
    }
  }
}
