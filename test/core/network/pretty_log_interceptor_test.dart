import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/core/network/pretty_log_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late List<String> output;
  late PrettyLogInterceptor interceptor;

  String dump() => output.join('\n');

  setUp(() {
    output = <String>[];
    interceptor = PrettyLogInterceptor(
      responseHeaders: true,
      printer: output.add,
    );
  });

  RequestOptions optionsFor(
    String method,
    String path, {
    Object? data,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? query,
  }) {
    return RequestOptions(
      path: path,
      method: method,
      baseUrl: 'http://localhost:8008/api/v1',
      data: data,
      headers: headers ?? <String, dynamic>{},
      queryParameters: query ?? <String, dynamic>{},
    );
  }

  group('onRequest', () {
    test('prints a boxed request block with method emoji and url', () {
      interceptor.onRequest(
        optionsFor('POST', '/auth/forgot-password/',
            data: {'phone': '+998909999999'}),
        RequestInterceptorHandler(),
      );

      expect(dump(), contains('REQUEST'));
      expect(dump(), contains('POST'));
      expect(dump(), contains('/auth/forgot-password/'));
      expect(dump(),
          contains('http://localhost:8008/api/v1/auth/forgot-password/'));
      expect(dump(), contains('+998909999999'));
    });

    test('stamps a correlation id and start time on extra', () {
      final options = optionsFor('GET', '/me/');
      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.extra[PrettyLogInterceptor.requestIdKey], isA<String>());
      expect(options.extra[PrettyLogInterceptor.startedAtKey], isA<int>());
      expect(
        dump(),
        contains(options.extra[PrettyLogInterceptor.requestIdKey] as String),
      );
    });

    test('redacts sensitive headers', () {
      interceptor.onRequest(
        optionsFor('GET', '/me/', headers: {
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiJ9.super-secret',
          'Accept': 'application/json',
        }),
        RequestInterceptorHandler(),
      );

      expect(dump(), isNot(contains('super-secret')));
      expect(dump(), contains('•'));
      expect(dump(), contains('Accept: application/json'));
    });

    test('redacts sensitive body fields but keeps the rest', () {
      interceptor.onRequest(
        optionsFor('POST', '/auth/login/', data: {
          'phone': '+998909999999',
          'password': 'hunter2',
          'nested': {'refresh_token': 'abc.def.ghi'},
        }),
        RequestInterceptorHandler(),
      );

      expect(dump(), isNot(contains('hunter2')));
      expect(dump(), isNot(contains('abc.def.ghi')));
      expect(dump(), contains('+998909999999'));
      expect(dump(), contains('"password"'));
    });

    test('pretty prints json body across multiple lines', () {
      interceptor.onRequest(
        optionsFor('POST', '/x/', data: {'a': 1, 'b': 2}),
        RequestInterceptorHandler(),
      );

      expect(dump(), contains('"a": 1'));
      expect(dump(), contains('"b": 2'));
    });

    test('prints query parameters when present', () {
      interceptor.onRequest(
        optionsFor('GET', '/items/', query: {'page': 2, 'search': 'phone'}),
        RequestInterceptorHandler(),
      );

      expect(dump(), contains('page: 2'));
      expect(dump(), contains('search: phone'));
    });

    test('summarises FormData instead of dumping bytes', () {
      final formData = FormData.fromMap({
        'title': 'avatar',
        'file': MultipartFile.fromBytes([1, 2, 3], filename: 'a.png'),
      });

      interceptor.onRequest(
        optionsFor('POST', '/upload/', data: formData),
        RequestInterceptorHandler(),
      );

      expect(dump(), contains('title: avatar'));
      expect(dump(), contains('a.png'));
    });

    test('truncates oversized bodies', () {
      final small = PrettyLogInterceptor(maxBodyChars: 40, printer: output.add);
      small.onRequest(
        optionsFor('POST', '/x/', data: {'blob': 'y' * 500}),
        RequestInterceptorHandler(),
      );

      expect(dump(), contains('truncated'));
      expect(dump().length, lessThan(600));
    });
  });

  group('onResponse', () {
    Response<Object?> responseFor(int code, Object? body, RequestOptions o) {
      return Response<Object?>(
        requestOptions: o,
        statusCode: code,
        statusMessage: 'Created',
        data: body,
        headers: Headers.fromMap({
          'content-type': ['application/json'],
        }),
      );
    }

    test('prints a success block with status, elapsed time and body', () {
      final options = optionsFor('POST', '/auth/forgot-password/');
      interceptor.onRequest(options, RequestInterceptorHandler());
      output.clear();

      interceptor.onResponse(
        responseFor(201, {'detail': "So'rovingiz administratorga yuborildi."},
            options),
        ResponseInterceptorHandler(),
      );

      expect(dump(), contains('RESPONSE'));
      expect(dump(), contains('201'));
      expect(dump(), contains('✅'));
      expect(dump(), contains('administratorga yuborildi'));
      expect(dump(), contains('ms'));
      expect(dump(), contains('content-type: application/json'));
    });

    test('uses a warning emoji for 4xx and a blast emoji for 5xx', () {
      final options = optionsFor('GET', '/x/');

      interceptor.onResponse(
        responseFor(404, null, options),
        ResponseInterceptorHandler(),
      );
      expect(dump(), contains('⚠️'));

      output.clear();
      interceptor.onResponse(
        responseFor(500, null, options),
        ResponseInterceptorHandler(),
      );
      expect(dump(), contains('💥'));
    });

    test('decodes a json string payload before pretty printing', () {
      final options = optionsFor('GET', '/x/');

      interceptor.onResponse(
        responseFor(200, '{"detail":"ok"}', options),
        ResponseInterceptorHandler(),
      );

      expect(dump(), contains('"detail": "ok"'));
    });
  });

  group('onError', () {
    // `handler.next(err)` completes the handler future with an error; nothing
    // consumes it in a unit test, so silence it to avoid a zone failure.
    ErrorInterceptorHandler errorHandler() {
      final handler = ErrorInterceptorHandler();
      // ignore: invalid_use_of_protected_member
      handler.future.ignore();
      return handler;
    }

    test('prints an error block with type, status and response body', () {
      final options = optionsFor('POST', '/auth/login/');
      interceptor.onRequest(options, RequestInterceptorHandler());
      output.clear();

      interceptor.onError(
        DioException(
          requestOptions: options,
          type: DioExceptionType.badResponse,
          message: 'Http status error [401]',
          response: Response<Object?>(
            requestOptions: options,
            statusCode: 401,
            statusMessage: 'Unauthorized',
            data: {'detail': 'No active account'},
          ),
        ),
        errorHandler(),
      );

      expect(dump(), contains('ERROR'));
      expect(dump(), contains('❌'));
      expect(dump(), contains('401'));
      expect(dump(), contains('badResponse'));
      expect(dump(), contains('No active account'));
    });

    test('prints connection errors that have no response', () {
      final options = optionsFor('GET', '/x/');

      interceptor.onError(
        DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
          message: 'Connection refused',
        ),
        errorHandler(),
      );

      expect(dump(), contains('connectionError'));
      expect(dump(), contains('Connection refused'));
    });
  });

  group('toggles', () {
    test('suppresses bodies and headers when disabled', () {
      final quiet = PrettyLogInterceptor(
        requestHeaders: false,
        requestBody: false,
        printer: output.add,
      );

      quiet.onRequest(
        optionsFor('POST', '/x/',
            data: {'phone': '+998909999999'},
            headers: {'Accept': 'application/json'}),
        RequestInterceptorHandler(),
      );

      expect(dump(), isNot(contains('+998909999999')));
      expect(dump(), isNot(contains('Accept: application/json')));
      expect(dump(), contains('REQUEST'));
    });
  });
}
