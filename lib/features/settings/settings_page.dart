import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/core/config/app_config.dart';
import 'package:flutter_boilerplate/core/firebase/firebase_bootstrap.dart';
import 'package:flutter_boilerplate/core/firebase/push_notification_service.dart';
import 'package:flutter_boilerplate/core/localization/locale_controller.dart';
import 'package:flutter_boilerplate/features/home/home_page.dart';
import 'package:flutter_boilerplate/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const routeName = 'settings';
  static const routePath = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final firebaseStatus = ref.watch(firebaseStatusProvider);
    final configured = firebaseStatus.value?.isConfigured ?? false;
    final locale = ref.watch(localeControllerProvider).value ??
        normalizeLocale(ref.watch(platformLocaleProvider));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.settingsTitle),
        leading: BackButton(
          onPressed: () => context.goNamed(HomePage.routeName),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _InfoTile(
            title: l10n.settingsEnvironment,
            value: AppConfig.isRelease
                ? l10n.environmentRelease
                : l10n.environmentDebug,
          ),
          _InfoTile(
            title: l10n.settingsApi,
            value: '${AppConfig.apiBaseUrl}/${AppConfig.apiVersion}',
          ),
          _InfoTile(
            title: l10n.homeFirebase,
            value: configured
                ? l10n.firebaseReady
                : l10n.firebaseUnconfigured,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<Locale>(
            initialValue: locale,
            decoration: InputDecoration(labelText: l10n.settingsLanguage),
            items: [
              for (final supported in supportedLocales)
                DropdownMenuItem(
                  value: supported,
                  child: Text(_localeName(l10n, supported)),
                ),
            ],
            onChanged: (selected) {
              if (selected == null) return;
              ref.read(localeControllerProvider.notifier).setLocale(selected);
            },
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: configured
                ? () => _requestNotifications(context, ref, l10n)
                : null,
            icon: const Icon(Icons.notifications_active_outlined),
            label: Text(l10n.settingsEnableNotifications),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: configured
                ? () => _copyFcmToken(context, l10n)
                : null,
            icon: const Icon(Icons.notifications_outlined),
            label: Text(l10n.settingsCheckFcmToken),
          ),
        ],
      ),
    );
  }

  Future<void> _requestNotifications(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final settings = await PushNotificationService.requestPermission();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_permissionMessage(l10n, settings.authorizationStatus))),
    );
  }

  Future<void> _copyFcmToken(BuildContext context, AppLocalizations l10n) async {
    final token = await PushNotificationService.getToken();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          token == null ? l10n.fcmTokenUnavailable : l10n.fcmTokenCopied,
        ),
      ),
    );
  }

  String _permissionMessage(
    AppLocalizations l10n,
    AuthorizationStatus status,
  ) {
    return switch (status) {
      AuthorizationStatus.authorized ||
      AuthorizationStatus.provisional =>
        l10n.notificationsEnabled,
      AuthorizationStatus.denied ||
      AuthorizationStatus.deniedPermanently =>
        l10n.notificationsDenied,
      AuthorizationStatus.notDetermined => l10n.notificationsUnavailable,
    };
  }

  String _localeName(AppLocalizations l10n, Locale locale) {
    switch (locale.languageCode) {
      case 'uz':
        return l10n.localeUzbek;
      case 'ru':
        return l10n.localeRussian;
      default:
        return l10n.localeEnglish;
    }
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
