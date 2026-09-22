## Why

The starter currently advertises production-ready localization and optional Firebase behavior, but visible strings are hardcoded, locale preference is not connected to the app, Firebase blocks startup, notification permission is requested immediately, and several dependencies are unused. Updating these foundations now keeps generated apps smaller, makes startup behavior predictable, and turns the documented en/uz/ru and Firebase flows into working defaults.

## What Changes

- Remove unused direct dependencies and upgrade the retained packages to compatible current releases.
- Generate en, uz, and ru localizations with Flutter `gen-l10n`; default to the system locale and persist an explicit Settings selection with `SharedPreferencesAsync`.
- Use the selected locale consistently for Flutter UI and API `Accept-Language` headers.
- Start the UI without waiting for Firebase; expose initialization state through Riverpod.
- Request notification permission only after an explicit Settings action while retaining foreground notifications and FCM token access.
- Reject release startup when the placeholder API endpoint is still configured.
- Pin the verified Flutter toolchain in CI and add an Android debug build smoke check.
- Update focused tests and documentation for the resulting behavior.

## Capabilities

### New Capabilities

- `app-localization`: Generated en/uz/ru UI strings, system-locale fallback, persisted user selection, and matching API locale headers.
- `firebase-notification-lifecycle`: Non-blocking Firebase startup plus explicit, user-triggered notification authorization.
- `release-configuration-safety`: Release builds reject the placeholder API endpoint before launching the application.

### Modified Capabilities

None.

## Impact

Affected areas include application bootstrap, Riverpod providers, MaterialApp configuration, Settings and Home UI, local preferences, Dio request headers, Firebase/notification initialization, ARB generation, package constraints and lockfile, CI, tests, and README/architecture documentation. Riverpod, GoRouter, Dio, secure storage, Firebase, local notifications, and `intl` remain; no new architecture, code-generation, logging, or database package is introduced.
