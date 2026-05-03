import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/config/app_config.dart';
import 'package:flutter_boilerplate/core/firebase/firebase_bootstrap.dart';
import 'package:flutter_boilerplate/core/firebase/push_notification_service.dart';
import 'package:flutter_boilerplate/features/home/home_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const routeName = 'settings';
  static const routePath = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firebaseStatus = ref.watch(firebaseStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        leading: BackButton(
          onPressed: () => context.goNamed(HomePage.routeName),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _InfoTile(
            title: 'Environment',
            value: AppConfig.isRelease ? 'release' : 'debug',
          ),
          const _InfoTile(
            title: 'API',
            value: '${AppConfig.apiBaseUrl}/${AppConfig.apiVersion}',
          ),
          _InfoTile(
            title: 'Firebase',
            value: firebaseStatus.isConfigured ? 'ready' : 'not configured',
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: firebaseStatus.isConfigured
                ? () async {
                    final token = await PushNotificationService.getToken();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(token == null ? 'FCM token unavailable.' : 'FCM token copied from service.'),
                      ),
                    );
                  }
                : null,
            icon: const Icon(Icons.notifications_outlined),
            label: const Text('Check FCM token'),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
