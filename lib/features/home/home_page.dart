import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/config/app_config.dart';
import 'package:flutter_boilerplate/core/firebase/firebase_bootstrap.dart';
import 'package:flutter_boilerplate/features/settings/settings_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const routeName = 'home';
  static const routePath = '/';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseStatus = ref.watch(firebaseStatusProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppConfig.appName),
        actions: [
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.goNamed(SettingsPage.routeName),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.rocket_launch_outlined,
                      size: 44,
                      color: colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Production Flutter starter',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onPrimaryContainer,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Riverpod, GoRouter, Dio, secure storage, Firebase-ready bootstrap.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: colorScheme.onPrimaryContainer,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _StatusTile(
              icon: Icons.api_outlined,
              title: 'API base URL',
              subtitle: AppConfig.apiBaseUrl,
            ),
            _StatusTile(
              icon: Icons.notifications_active_outlined,
              title: 'Firebase',
              subtitle: firebaseStatus.isConfigured ? 'Configured' : 'Not configured yet',
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => context.goNamed(SettingsPage.routeName),
              icon: const Icon(Icons.tune_outlined),
              label: const Text('Open settings'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
