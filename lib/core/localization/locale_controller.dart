import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';
import 'package:flutter_boilerplate/core/localization/locale_store.dart';
import 'package:flutter_boilerplate/core/storage/local_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:flutter_boilerplate/core/localization/locale_store.dart';

/// Locales the generated localization resources provide.
const supportedLocales = <Locale>[Locale('en'), Locale('uz'), Locale('ru')];

/// Maps any locale to a supported one, defaulting to English.
Locale normalizeLocale(Locale locale) => supportedLocales.firstWhere(
      (candidate) => candidate.languageCode == locale.languageCode,
      orElse: () => const Locale('en'),
    );

/// The device locale, overrideable in tests.
final platformLocaleProvider = Provider<Locale>(
  (ref) => PlatformDispatcher.instance.locale,
);

/// The persisted active locale, backed by [LocalStorage].
final localeStoreProvider = Provider<LocaleStore>(
  (ref) => ref.watch(localStorageProvider),
);

final localeControllerProvider =
    AsyncNotifierProvider<LocaleController, Locale>(LocaleController.new);

/// Resolves the active locale: a valid saved selection wins, otherwise the
/// normalized system locale. Used by both the UI controller and networking so
/// the `Accept-Language` header always matches the visible language.
Future<Locale> resolveActiveLocale(
  LocaleStore store, {
  Locale? platformLocale,
}) async {
  final fallback = normalizeLocale(
    platformLocale ?? PlatformDispatcher.instance.locale,
  );
  final saved = await store.readLocaleCode();
  if (saved != null && saved.isNotEmpty) {
    final candidate = Locale(saved);
    if (supportedLocales.any(
      (supported) => supported.languageCode == candidate.languageCode,
    )) {
      return normalizeLocale(candidate);
    }
  }
  return fallback;
}

class LocaleController extends AsyncNotifier<Locale> {
  @override
  Future<Locale> build() async {
    final store = ref.watch(localeStoreProvider);
    final platformLocale = ref.watch(platformLocaleProvider);
    // Legacy migration and token purge run before the locale is resolved.
    await ref.watch(startupMaintenanceProvider.future);
    return resolveActiveLocale(store, platformLocale: platformLocale);
  }

  /// Persists [locale] before exposing it so a restart restores the choice.
  Future<void> setLocale(Locale locale) async {
    final normalized = normalizeLocale(locale);
    await ref.read(localeStoreProvider).writeLocaleCode(normalized.languageCode);
    state = AsyncData(normalized);
  }
}
