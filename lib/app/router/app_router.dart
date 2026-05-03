import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/features/home/home_page.dart';
import 'package:flutter_boilerplate/features/settings/settings_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final rootNavigatorKeyProvider = Provider<GlobalKey<NavigatorState>>(
  (ref) => GlobalKey<NavigatorState>(),
);

final scaffoldMessengerKeyProvider = Provider<GlobalKey<ScaffoldMessengerState>>(
  (ref) => GlobalKey<ScaffoldMessengerState>(),
);

final appRouterProvider = Provider<GoRouter>((ref) {
  final rootNavigatorKey = ref.watch(rootNavigatorKeyProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: HomePage.routePath,
    routes: [
      GoRoute(
        path: HomePage.routePath,
        name: HomePage.routeName,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: SettingsPage.routePath,
        name: SettingsPage.routeName,
        builder: (context, state) => const SettingsPage(),
      ),
    ],
  );
});
