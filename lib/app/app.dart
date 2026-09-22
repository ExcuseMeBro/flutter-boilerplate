import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/app/router/app_router.dart';
import 'package:flutter_boilerplate/app/theme/app_theme.dart';
import 'package:flutter_boilerplate/core/localization/locale_controller.dart';
import 'package:flutter_boilerplate/core/storage/local_storage.dart';
import 'package:flutter_boilerplate/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BoilerplateApp extends ConsumerWidget {
  const BoilerplateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Runs the legacy plaintext-token cleanup once, off the first frame.
    ref.watch(legacyTokenPurgeProvider);

    final router = ref.watch(appRouterProvider);
    final scaffoldMessengerKey = ref.watch(scaffoldMessengerKeyProvider);
    final localeAsync = ref.watch(localeControllerProvider);
    final locale = localeAsync.value ??
        normalizeLocale(ref.watch(platformLocaleProvider));

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      scaffoldMessengerKey: scaffoldMessengerKey,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
    );
  }
}
