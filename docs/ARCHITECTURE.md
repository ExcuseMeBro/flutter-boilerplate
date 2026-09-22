# Architecture

This template keeps only reusable production foundations from BabyTime mobile app.

## Rules

- Feature-first folders under `lib/features`.
- Shared infrastructure under `lib/core`.
- Generated code only from Flutter `gen-l10n` (`lib/l10n`); no other code generation by default.
- No app-specific screens, assets, endpoints, or secrets.
- All environment-specific values come from `--dart-define`.

## Bootstrap

`main` performs only synchronous Flutter/system setup, validates release
configuration, and calls `runApp`. It never awaits preferences or Firebase, so
the first frame is not blocked. `BoilerplateApp` watches the async locale
controller and the Firebase status provider and renders while either is still
loading.

## Localization

`lib/core/localization/locale_controller.dart` owns the locale rules:

- `normalizeLocale` maps any locale to `en`, `uz`, or `ru`, defaulting to `en`.
- `LocaleController` is an `AsyncNotifier<Locale>`: a valid saved selection wins,
  otherwise the normalized system locale is used. An invalid stored value falls
  back through the same system-locale rule.
- `setLocale` persists the choice through the `LocaleStore` seam (implemented by
  `LocalStorage` on `SharedPreferencesAsync`) before exposing it.
- `resolveActiveLocale` is shared with networking so API `Accept-Language`
  always matches the visible language.

`lib/l10n/*.arb` are the sources; generated delegates and locales are committed
under `lib/l10n/app_localizations*.dart`.

## Networking

`ApiClient` wraps Dio and exposes typed request helpers. `AuthInterceptor` adds
the active language header, the bearer token, and one-shot token refresh for
`401` responses.

Refresh endpoint default: `/auth/refresh/` under configured API base.

## Storage

- Access/refresh tokens are saved in platform secure storage.
- `SharedPreferencesAsync` holds non-sensitive preferences such as locale.
- Legacy plaintext tokens are purged once after startup.
- A locale saved by an older build in the legacy `SharedPreferences` store is
  promoted into `SharedPreferencesAsync` when the async value is missing.
- `clearAuth()` clears both token keys.

## Firebase

`firebaseStatusProvider` is a non-auto-disposed `FutureProvider` that runs
`FirebaseBootstrap.initialize()` on demand. Initialization catches missing
Firebase configuration and reports an unconfigured status instead of failing.

`PushNotificationService.initialize()` registers the plugin, channel, and
foreground listener only. Permission is requested exclusively by
`PushNotificationService.requestPermission()`, invoked from the Settings action.

## Release configuration

`AppConfig.validate` is a pure seam called before `runApp`. In release mode it
rejects a missing, malformed, non-HTTPS, or placeholder (`api.example.com`) API
base URL; debug and test builds keep the template defaults.
