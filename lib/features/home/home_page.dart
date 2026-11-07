import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/features/settings/settings_page.dart';
import 'package:flutter_boilerplate/l10n/app_localizations.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const routeName = 'home';
  static const routePath = '/';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.appTitle)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.all(24),
              children: [
                Text(l10n.homeHeadline, style: text.headlineSmall),
                const SizedBox(height: 16),
                Text(l10n.homeSubtitle, style: text.bodyLarge),
                const SizedBox(height: 24),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: FilledButton.icon(
                    onPressed: () => context.goNamed(SettingsPage.routeName),
                    icon: const Icon(Icons.settings_outlined),
                    label: Text(l10n.homeOpenSettings),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
