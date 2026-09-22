import 'package:flutter/widgets.dart';
import 'package:flutter_boilerplate/core/localization/locale_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// In-memory [LocaleStore] seam; no mocking package required.
class FakeLocaleStore implements LocaleStore {
  FakeLocaleStore({this.savedCode});

  String? savedCode;
  int writes = 0;

  @override
  Future<String?> readLocaleCode() async => savedCode;

  @override
  Future<void> writeLocaleCode(String code) async {
    savedCode = code;
    writes++;
  }
}

void main() {
  group('normalizeLocale', () {
    test('keeps a supported language and drops the region', () {
      expect(normalizeLocale(const Locale('uz', 'UZ')), const Locale('uz'));
    });

    test('falls back to English for an unsupported locale', () {
      expect(normalizeLocale(const Locale('de')), const Locale('en'));
    });
  });

  group('LocaleController', () {
    ProviderContainer containerWith({String? saved, required Locale platform}) {
      final container = ProviderContainer(
        overrides: [
          localeStoreProvider.overrideWithValue(
            FakeLocaleStore(savedCode: saved),
          ),
          platformLocaleProvider.overrideWithValue(platform),
        ],
      );
      addTearDown(container.dispose);
      return container;
    }

    test('starts in the supported system locale when nothing is saved',
        () async {
      final container = containerWith(platform: const Locale('uz'));

      expect(
        await container.read(localeControllerProvider.future),
        const Locale('uz'),
      );
    });

    test('falls back to English for an unsupported system locale', () async {
      final container = containerWith(platform: const Locale('de'));

      expect(
        await container.read(localeControllerProvider.future),
        const Locale('en'),
      );
    });

    test('restores the saved locale over the system locale', () async {
      final container = containerWith(saved: 'ru', platform: const Locale('uz'));

      expect(
        await container.read(localeControllerProvider.future),
        const Locale('ru'),
      );
    });

    test('ignores an invalid saved locale and uses the system locale',
        () async {
      final container = containerWith(saved: 'de', platform: const Locale('ru'));

      expect(
        await container.read(localeControllerProvider.future),
        const Locale('ru'),
      );
    });

    test('persists an explicit selection and exposes it immediately',
        () async {
      final store = FakeLocaleStore();
      final container = ProviderContainer(
        overrides: [
          localeStoreProvider.overrideWithValue(store),
          platformLocaleProvider.overrideWithValue(const Locale('en')),
        ],
      );
      addTearDown(container.dispose);

      await container.read(localeControllerProvider.future);
      await container
          .read(localeControllerProvider.notifier)
          .setLocale(const Locale('uz'));

      expect(store.savedCode, 'uz');
      expect(store.writes, 1);
      expect(container.read(localeControllerProvider).value, const Locale('uz'));
    });
  });
}
