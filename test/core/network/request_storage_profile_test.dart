import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_boilerplate/core/network/auth_interceptor.dart';
import 'package:flutter_boilerplate/core/storage/local_storage.dart';
import 'package:flutter_boilerplate/core/storage/secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/in_memory_preferences.dart';

class _SecureBackend extends FlutterSecureStorage {
  int reads = 0;

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    reads++;
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return 'synthetic-token';
  }
}

class _Preferences extends SharedPreferencesAsync {
  final reads = <int>[0];

  @override
  Future<String?> getString(String key) async {
    reads[0]++;
    await Future<void>.delayed(const Duration(milliseconds: 1));
    return 'en';
  }
}

class _Adapter implements HttpClientAdapter {
  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  installInMemoryPreferences();
  test(
    'repeatable request storage profile (synthetic 1 ms platform reads)',
    () async {
      for (final concurrency in [1, 10, 100]) {
        final samples = <int>[];
        final counts = <List<int>>[];
        for (var run = 0; run < 7; run++) {
          final secure = _SecureBackend();
          final prefs = _Preferences();
          final local = LocalStorage(prefs);
          await local.migrateLegacyLocale();
          final dio = Dio(BaseOptions(baseUrl: 'https://profile.invalid'))
            ..httpClientAdapter = _Adapter();
          dio.interceptors.add(
            AuthInterceptor(
              secureStorage: SecureStorage(storage: secure),
              localStorage: local,
              dio: dio,
              refreshUri: Uri.parse('https://profile.invalid/refresh'),
            ),
          );
          // Warm up framework paths, excluding startup migration and JIT warmup.
          await dio.get<dynamic>('/warmup');
          secure.reads = 0;
          prefs.reads[0] = 0;
          final watch = Stopwatch()..start();
          for (var batch = 0; batch < 100 ~/ concurrency; batch++) {
            await Future.wait(
              List.generate(concurrency, (_) => dio.get<dynamic>('/request')),
            );
          }
          watch.stop();
          samples.add(watch.elapsedMicroseconds);
          counts.add([secure.reads, prefs.reads[0]]);
          dio.close(force: true);
        }
        samples.sort();
        // Only aggregate timings and counts are emitted, never headers/tokens.
        // ignore: avoid_print
        print(
          jsonEncode({
            'concurrency': concurrency,
            'requests_per_run': 100,
            'runs': 7,
            'median_us': samples[3],
            'min_us': samples.first,
            'max_us': samples.last,
            'secure_and_locale_reads': counts,
          }),
        );
      }
    },
  );
}
