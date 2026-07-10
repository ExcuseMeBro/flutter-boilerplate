import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/core/network/api_client.dart';
import 'package:flutter_boilerplate/core/network/auth_interceptor.dart';
import 'package:flutter_boilerplate/core/storage/local_storage.dart';
import 'package:flutter_boilerplate/core/storage/secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSecureStorage implements SecureStorage {
  FakeSecureStorage({this.access, this.refresh});

  String? access;
  String? refresh;
  int clearCount = 0;

  @override
  Future<String?> getAccessToken() async => access;

  @override
  Future<String?> getRefreshToken() async => refresh;

  @override
  Future<void> setAccessToken(String token) async => access = token;

  @override
  Future<void> setRefreshToken(String token) async => refresh = token;

  @override
  Future<void> clearAuth() async {
    clearCount++;
    access = null;
    refresh = null;
  }
}

/// Serves canned responses and records every request that reaches the wire.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this._handler);

  final Future<ResponseBody> Function(RequestOptions options) _handler;
  final requests = <RequestOptions>[];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    requests.add(options);
    return _handler(options);
  }
}

ResponseBody _json(Object body, int status) => ResponseBody.fromString(
      jsonEncode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorage localStorage;
  final refreshUri = Uri.parse('https://api.test/api/v1/auth/refresh/');

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    localStorage = LocalStorage(await SharedPreferences.getInstance());
  });

  /// Builds a Dio whose only interceptor is the one under test.
  ({Dio dio, FakeAdapter api, FakeAdapter refreshApi, AuthInterceptor sut})
      buildClient({
    required FakeSecureStorage secureStorage,
    required Future<ResponseBody> Function(RequestOptions) apiHandler,
    required Future<ResponseBody> Function(RequestOptions) refreshHandler,
    void Function()? onAuthFailure,
  }) {
    final api = FakeAdapter(apiHandler);
    final refreshApi = FakeAdapter(refreshHandler);

    final dio = Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))
      ..httpClientAdapter = api;
    final refreshClient = Dio()..httpClientAdapter = refreshApi;

    final sut = AuthInterceptor(
      secureStorage: secureStorage,
      localStorage: localStorage,
      dio: dio,
      refreshUri: refreshUri,
      refreshClient: refreshClient,
      onAuthFailure: onAuthFailure,
    );
    dio.interceptors.add(sut);

    return (dio: dio, api: api, refreshApi: refreshApi, sut: sut);
  }

  group('ApiClient.refreshUri', () {
    test('keeps the api version segment instead of resolving to host root', () {
      // A leading slash in resolve() would silently drop `/api/v1`.
      expect(ApiClient.refreshUri.path, endsWith('/v1/auth/refresh/'));
      expect(ApiClient.refreshUri.path, isNot(startsWith('/auth/refresh/')));
    });
  });

  group('onRequest', () {
    test('attaches the bearer token and the locale header', () async {
      final storage = FakeSecureStorage(access: 'token-a');
      final client = buildClient(
        secureStorage: storage,
        apiHandler: (_) async => _json({'ok': true}, 200),
        refreshHandler: (_) async => _json({}, 200),
      );

      await client.dio.get<dynamic>('/me/');

      final sent = client.api.requests.single;
      expect(sent.headers['Authorization'], 'Bearer token-a');
      expect(sent.headers['Accept-Language'], 'en');
    });

    test('skips the bearer token when the request opts out of auth', () async {
      final storage = FakeSecureStorage(access: 'token-a');
      final client = buildClient(
        secureStorage: storage,
        apiHandler: (_) async => _json({'ok': true}, 200),
        refreshHandler: (_) async => _json({}, 200),
      );

      await client.dio.post<dynamic>(
        '/auth/login/',
        options: Options(extra: {AuthInterceptor.skipAuthExtraKey: true}),
      );

      expect(client.api.requests.single.headers['Authorization'], isNull);
    });
  });

  group('refresh on 401', () {
    test('refreshes once, then replays the request with the new token',
        () async {
      final storage = FakeSecureStorage(access: 'stale', refresh: 'r1');
      var refreshCalls = 0;

      final client = buildClient(
        secureStorage: storage,
        apiHandler: (options) async =>
            options.headers['Authorization'] == 'Bearer fresh'
                ? _json({'ok': true}, 200)
                : _json({'detail': 'expired'}, 401),
        refreshHandler: (_) async {
          refreshCalls++;
          return _json({'access': 'fresh', 'refresh': 'r2'}, 200);
        },
      );

      final response = await client.dio.get<Map<String, dynamic>>('/me/');

      expect(response.statusCode, 200);
      expect(refreshCalls, 1);
      expect(storage.access, 'fresh');
      expect(storage.refresh, 'r2');
      expect(client.api.requests.length, 2);
      expect(client.api.requests.last.headers['Authorization'], 'Bearer fresh');
    });

    test('coalesces concurrent 401s into a single refresh call', () async {
      final storage = FakeSecureStorage(access: 'stale', refresh: 'r1');
      var refreshCalls = 0;

      final client = buildClient(
        secureStorage: storage,
        apiHandler: (options) async =>
            options.headers['Authorization'] == 'Bearer fresh'
                ? _json({'ok': true}, 200)
                : _json({'detail': 'expired'}, 401),
        refreshHandler: (_) async {
          refreshCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return _json({'access': 'fresh', 'refresh': 'r2'}, 200);
        },
      );

      await Future.wait([
        client.dio.get<dynamic>('/a/'),
        client.dio.get<dynamic>('/b/'),
        client.dio.get<dynamic>('/c/'),
      ]);

      expect(refreshCalls, 1, reason: 'refresh token must be spent once');
    });

    test('retries without refreshing when the token was already rotated',
        () async {
      final storage = FakeSecureStorage(access: 'fresh', refresh: 'r1');
      var refreshCalls = 0;

      final client = buildClient(
        secureStorage: storage,
        apiHandler: (options) async =>
            options.headers['Authorization'] == 'Bearer fresh'
                ? _json({'ok': true}, 200)
                : _json({'detail': 'expired'}, 401),
        refreshHandler: (_) async {
          refreshCalls++;
          return _json({'access': 'fresh', 'refresh': 'r2'}, 200);
        },
      );

      // Request built before the rotation still carries the stale token.
      final response = await client.dio.get<dynamic>(
        '/me/',
        options: Options(headers: {'Authorization': 'Bearer stale'}),
      );

      expect(response.statusCode, 200);
      expect(refreshCalls, 0, reason: 'a rotated token needs no new refresh');
    });

    test('replays multipart uploads with a cloned FormData body', () async {
      final storage = FakeSecureStorage(access: 'stale', refresh: 'r1');
      final client = buildClient(
        secureStorage: storage,
        apiHandler: (options) async =>
            options.headers['Authorization'] == 'Bearer fresh'
                ? _json({'ok': true}, 200)
                : _json({'detail': 'expired'}, 401),
        refreshHandler: (_) async => _json({'access': 'fresh'}, 200),
      );

      final original = FormData.fromMap({
        'file': MultipartFile.fromBytes([1, 2, 3], filename: 'a.png'),
      });
      final response = await client.dio.post<dynamic>('/upload/', data: original);

      expect(response.statusCode, 200);
      final replayed = client.api.requests.last.data as FormData;
      expect(identical(replayed, original), isFalse,
          reason: 'a finalized FormData stream cannot be replayed');
      expect(replayed.files.single.value.filename, 'a.png');
    });

    test('clears credentials and signals logout when the refresh fails',
        () async {
      final storage = FakeSecureStorage(access: 'stale', refresh: 'r1');
      var loggedOut = false;

      final client = buildClient(
        secureStorage: storage,
        apiHandler: (_) async => _json({'detail': 'expired'}, 401),
        refreshHandler: (_) async => _json({'detail': 'invalid'}, 401),
        onAuthFailure: () => loggedOut = true,
      );

      await expectLater(
        client.dio.get<dynamic>('/me/'),
        throwsA(isA<DioException>()),
      );

      expect(storage.clearCount, 1);
      expect(storage.access, isNull);
      expect(loggedOut, isTrue);
    });

    test('does not refresh when there is no refresh token', () async {
      final storage = FakeSecureStorage(access: 'stale');
      var refreshCalls = 0;

      final client = buildClient(
        secureStorage: storage,
        apiHandler: (_) async => _json({'detail': 'expired'}, 401),
        refreshHandler: (_) async {
          refreshCalls++;
          return _json({}, 200);
        },
      );

      await expectLater(
        client.dio.get<dynamic>('/me/'),
        throwsA(isA<DioException>()),
      );
      expect(refreshCalls, 0);
    });

    test('does not refresh for requests that opted out of auth', () async {
      final storage = FakeSecureStorage(access: 'stale', refresh: 'r1');
      var refreshCalls = 0;

      final client = buildClient(
        secureStorage: storage,
        apiHandler: (_) async => _json({'detail': 'bad creds'}, 401),
        refreshHandler: (_) async {
          refreshCalls++;
          return _json({}, 200);
        },
      );

      await expectLater(
        client.dio.post<dynamic>(
          '/auth/login/',
          options: Options(extra: {AuthInterceptor.skipAuthExtraKey: true}),
        ),
        throwsA(isA<DioException>()),
      );
      expect(refreshCalls, 0);
      expect(storage.clearCount, 0);
    });

    test('gives up after one retry instead of looping', () async {
      final storage = FakeSecureStorage(access: 'stale', refresh: 'r1');
      var refreshCalls = 0;

      final client = buildClient(
        secureStorage: storage,
        apiHandler: (_) async => _json({'detail': 'expired'}, 401),
        refreshHandler: (_) async {
          refreshCalls++;
          return _json({'access': 'fresh', 'refresh': 'r2'}, 200);
        },
      );

      await expectLater(
        client.dio.get<dynamic>('/me/'),
        throwsA(isA<DioException>()),
      );
      expect(refreshCalls, 1);
      expect(client.api.requests.length, 2);
    });

    test('sends the refresh call to the configured refresh endpoint', () async {
      final storage = FakeSecureStorage(access: 'stale', refresh: 'r1');
      final client = buildClient(
        secureStorage: storage,
        apiHandler: (options) async =>
            options.headers['Authorization'] == 'Bearer fresh'
                ? _json({'ok': true}, 200)
                : _json({'detail': 'expired'}, 401),
        refreshHandler: (_) async => _json({'access': 'fresh'}, 200),
      );

      await client.dio.get<dynamic>('/me/');

      final refreshRequest = client.refreshApi.requests.single;
      expect(refreshRequest.uri, refreshUri);
      expect(refreshRequest.headers.containsKey('Authorization'), isFalse);
      expect(refreshRequest.connectTimeout, isNotNull);
    });
  });

  group('LocalStorage', () {
    test('purges tokens leaked into prefs by previous app versions', () async {
      SharedPreferences.setMockInitialValues({
        'Flutter Boilerplate.accessToken': 'leaked-access',
        'Flutter Boilerplate.refreshToken': 'leaked-refresh',
        'Flutter Boilerplate.locale': 'uz',
      });
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);

      await storage.purgeLegacyTokens();

      expect(prefs.getString('Flutter Boilerplate.accessToken'), isNull);
      expect(prefs.getString('Flutter Boilerplate.refreshToken'), isNull);
      expect(storage.getLocaleCode(), 'uz', reason: 'locale must survive');
    });
  });
}
