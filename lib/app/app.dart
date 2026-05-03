import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/app/router/app_router.dart';
import 'package:flutter_boilerplate/app/theme/app_theme.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BoilerplateApp extends ConsumerWidget {
  const BoilerplateApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final scaffoldMessengerKey = ref.watch(scaffoldMessengerKeyProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Boilerplate',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: router,
      scaffoldMessengerKey: scaffoldMessengerKey,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('uz'),
        Locale('ru'),
      ],
    );
  }
}
