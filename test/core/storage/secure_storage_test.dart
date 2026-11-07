import 'dart:async';

import 'package:flutter_boilerplate/core/storage/secure_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

class _Backend extends FlutterSecureStorage {
  final values = <String, String>{};
  Completer<void>? started;
  Completer<void>? release;
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
    final snapshot = values[key];
    if (started != null && !started!.isCompleted) {
      started!.complete();
      await release!.future;
    }
    return snapshot;
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values[key] = value!;
  }

  @override
  Future<void> delete({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }
}

void main() {
  test(
    'secure storage persists login/rotation, then clears both keys on logout',
    () async {
      final backend = _Backend();
      final storage = SecureStorage(storage: backend);
      expect(await storage.getAccessToken(), isNull);
      await storage.setAccessToken('synthetic-access');
      await storage.setRefreshToken('synthetic-refresh');
      expect(await storage.getAccessToken(), 'synthetic-access');
      expect(await storage.getRefreshToken(), 'synthetic-refresh');
      await storage.setAccessToken('rotated-access');
      await storage.setRefreshToken('rotated-refresh');
      expect(await storage.getAccessToken(), 'rotated-access');
      expect(await storage.getRefreshToken(), 'rotated-refresh');
      await storage.clearAuth();
      expect(await storage.getAccessToken(), isNull);
      expect(await storage.getRefreshToken(), isNull);
      expect(backend.values, isEmpty);
    },
  );

  test(
    'overlapping secure reads share work; an in-flight pre-logout token is discarded',
    () async {
      final backend = _Backend()
        ..started = Completer<void>()
        ..release = Completer<void>();
      final storage = SecureStorage(storage: backend);
      await storage.setAccessToken('synthetic-access');
      final one = storage.getAccessToken();
      final two = storage.getAccessToken();
      await backend.started!.future;
      expect(backend.reads, 1);
      await storage.clearAuth();
      backend.release!.complete();
      expect(await Future.wait([one, two]), [null, null]);
      expect(backend.values, isEmpty);
    },
  );
}
