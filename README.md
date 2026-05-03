# Flutter Boilerplate

Production-ready Flutter starter based on patterns from BabyTime mobile app, cleaned for reuse.

## Stack

- Flutter stable / Dart 3
- Riverpod for dependency injection and state
- GoRouter for navigation
- Dio API client with auth headers and safe token refresh
- SharedPreferences + Flutter Secure Storage
- Optional Firebase Core, FCM, and local notifications
- Strict linting and CI

## Quick start

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=https://api.example.com --dart-define=API_VERSION=v1
```

## Create app from template

1. Click **Use this template** on GitHub.
2. Rename package IDs:
   - Android: `android/app/build.gradle.kts` `namespace` and `applicationId`
   - iOS: Runner bundle identifier in Xcode
3. Configure Firebase if needed:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

4. Run checks:

```bash
flutter pub get
flutter analyze
flutter test
```

## Dart defines

| Key | Default | Purpose |
| --- | --- | --- |
| `APP_NAME` | `Flutter Boilerplate` | App title |
| `API_BASE_URL` | `https://api.example.com` | Backend base URL |
| `API_VERSION` | `v1` | API version path |

## Structure

```text
lib/
  app/                 # app widget, router, theme
  core/
    config/            # compile-time config
    firebase/          # optional Firebase bootstrap and FCM
    network/           # Dio client, interceptors, errors
    storage/           # local and secure storage
  features/            # feature-first modules
```

## Notes

Firebase is optional. App builds without Firebase config; bootstrap catches missing native config and keeps app running.
