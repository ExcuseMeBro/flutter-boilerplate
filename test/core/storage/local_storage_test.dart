import 'dart:async';

import 'package:flutter_boilerplate/core/config/app_config.dart';
import 'package:flutter_boilerplate/core/storage/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/in_memory_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('migrates a legacy locale into async storage and returns it', () async {
    SharedPreferences.setMockInitialValues({
      '${AppConfig.appName}.locale': 'uz',
    });
    final async = installInMemoryPreferences();
    final storage = LocalStorage(async);

    expect(await storage.readLocaleCode(), 'uz');
    expect(
      await async.getString('${AppConfig.appName}.locale'),
      'uz',
      reason: 'a legacy locale must be promoted into the active async store',
    );
  });

  test('keeps an existing async locale over a stale legacy value', () async {
    SharedPreferences.setMockInitialValues({
      '${AppConfig.appName}.locale': 'ru',
    });
    final async = installInMemoryPreferences({
      '${AppConfig.appName}.locale': 'en',
    });
    final storage = LocalStorage(async);

    expect(await storage.readLocaleCode(), 'en');
  });

  test('startup migration keeps a newer async locale over a stale legacy value',
      () async {
    SharedPreferences.setMockInitialValues({
      '${AppConfig.appName}.locale': 'ru',
    });
    final async = installInMemoryPreferences({
      '${AppConfig.appName}.locale': 'en',
    });
    final storage = LocalStorage(async);

    expect(await storage.migrateLegacyLocale(), 'en');
    expect(
      await async.getString('${AppConfig.appName}.locale'),
      'en',
      reason: 'startup migration must not overwrite a newer user selection',
    );
  });

  test('an explicit locale written during migration wins over a late legacy value',
      () async {
    final legacyCompleter = Completer<SharedPreferences>();
    final async = installInMemoryPreferences();
    final storage = LocalStorage(
      async,
      legacyPreferences: () => legacyCompleter.future,
    );

    final migration = storage.migrateLegacyLocale();
    final write = storage.writeLocaleCode('en');

    SharedPreferences.setMockInitialValues({
      '${AppConfig.appName}.locale': 'ru',
    });
    legacyCompleter.complete(await SharedPreferences.getInstance());

    await Future.wait([migration, write]);
    expect(
      await async.getString('${AppConfig.appName}.locale'),
      'en',
      reason: 'a late legacy value must not overwrite the newer selection',
    );
    expect(await storage.readLocaleCode(), 'en');
  });

  test('a write that starts first still waits for a blocked migration', () async {
    final legacyCompleter = Completer<SharedPreferences>();
    final async = installInMemoryPreferences();
    final storage = LocalStorage(
      async,
      legacyPreferences: () => legacyCompleter.future,
    );

    var writeCompleted = false;
    final write = storage
        .writeLocaleCode('en')
        .then((_) => writeCompleted = true);

    await Future<void>.delayed(Duration.zero);
    expect(
      writeCompleted,
      isFalse,
      reason: 'the write must not land before the migration resolves',
    );
    expect(await async.getString('${AppConfig.appName}.locale'), isNull);

    SharedPreferences.setMockInitialValues({
      '${AppConfig.appName}.locale': 'ru',
    });
    legacyCompleter.complete(await SharedPreferences.getInstance());
    await write;

    expect(
      await async.getString('${AppConfig.appName}.locale'),
      'en',
      reason: 'legacy must not overwrite a selection written during startup',
    );
    expect(await storage.readLocaleCode(), 'en');
  });

  test('purges legacy plaintext tokens from both async and legacy stores',
      () async {
    SharedPreferences.setMockInitialValues({
      '${AppConfig.appName}.accessToken': 'legacy-access',
      '${AppConfig.appName}.refreshToken': 'legacy-refresh',
      '${AppConfig.appName}.locale': 'uz',
    });
    final legacy = await SharedPreferences.getInstance();
    final async = installInMemoryPreferences({
      '${AppConfig.appName}.accessToken': 'async-access',
      '${AppConfig.appName}.refreshToken': 'async-refresh',
    });
    final storage = LocalStorage(async);

    await storage.purgeLegacyTokens();

    expect(await async.getString('${AppConfig.appName}.accessToken'), isNull);
    expect(await async.getString('${AppConfig.appName}.refreshToken'), isNull);
    expect(legacy.getString('${AppConfig.appName}.accessToken'), isNull);
    expect(legacy.getString('${AppConfig.appName}.refreshToken'), isNull);
    expect(
      legacy.getString('${AppConfig.appName}.locale'),
      'uz',
      reason: 'token purge must not remove the locale',
    );
  });
}
