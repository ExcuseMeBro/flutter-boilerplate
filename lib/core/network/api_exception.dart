import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.path,
  });

  final String message;
  final int? statusCode;
  final String? path;

  factory ApiException.fromDio(DioException error) {
    final data = error.response?.data;
    final message = switch (data) {
      {'detail': final String detail} => detail,
      {'message': final String value} => value,
      {'error': final String value} => value,
      _ => _fallbackMessage(error),
    };

    return ApiException(
      message: message,
      statusCode: error.response?.statusCode,
      path: error.requestOptions.path,
    );
  }

  static String _fallbackMessage(DioException error) {
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout => 'Request timed out.',
      DioExceptionType.connectionError => 'No internet connection.',
      DioExceptionType.cancel => 'Request cancelled.',
      _ => 'Unexpected server error.',
    };
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}
