import 'package:flutter_boilerplate/core/storage/local_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/in_memory_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('migrates a legacy locale into async storage and returns it', () async {
    SharedPreferences.setMockInitialValues({
      'Flutter Boilerplate.locale': 'uz',
    });
    final async = installInMemoryPreferences();
    final storage = LocalStorage(async);

    expect(await storage.readLocaleCode(), 'uz');
    expect(
      await async.getString('Flutter Boilerplate.locale'),
      'uz',
      reason: 'a legacy locale must be promoted into the active async store',
    );
  });

  test('keeps an existing async locale over a stale legacy value', () async {
    SharedPreferences.setMockInitialValues({
      'Flutter Boilerplate.locale': 'ru',
    });
    final async = installInMemoryPreferences({
      'Flutter Boilerplate.locale': 'en',
    });
    final storage = LocalStorage(async);

    expect(await storage.readLocaleCode(), 'en');
  });

  test('startup migration keeps a newer async locale over a stale legacy value',
      () async {
    SharedPreferences.setMockInitialValues({
      'Flutter Boilerplate.locale': 'ru',
    });
    final async = installInMemoryPreferences({
      'Flutter Boilerplate.locale': 'en',
    });
    final storage = LocalStorage(async);

    expect(await storage.migrateLegacyLocale(), 'en');
    expect(
      await async.getString('Flutter Boilerplate.locale'),
      'en',
      reason: 'startup migration must not overwrite a newer user selection',
    );
  });

  test('purges legacy plaintext tokens from both async and legacy stores',
      () async {
    SharedPreferences.setMockInitialValues({
      'Flutter Boilerplate.accessToken': 'legacy-access',
      'Flutter Boilerplate.refreshToken': 'legacy-refresh',
      'Flutter Boilerplate.locale': 'uz',
    });
    final legacy = await SharedPreferences.getInstance();
    final async = installInMemoryPreferences({
      'Flutter Boilerplate.accessToken': 'async-access',
      'Flutter Boilerplate.refreshToken': 'async-refresh',
    });
    final storage = LocalStorage(async);

    await storage.purgeLegacyTokens();

    expect(await async.getString('Flutter Boilerplate.accessToken'), isNull);
    expect(await async.getString('Flutter Boilerplate.refreshToken'), isNull);
    expect(legacy.getString('Flutter Boilerplate.accessToken'), isNull);
    expect(legacy.getString('Flutter Boilerplate.refreshToken'), isNull);
    expect(
      legacy.getString('Flutter Boilerplate.locale'),
      'uz',
      reason: 'token purge must not remove the locale',
    );
  });
}
