# 🚀 Flutter Boilerplate

A clean, production-ready Flutter starter for building mobile apps faster. It ships with routing, state management, networking, secure authentication storage, optional Firebase messaging, local notifications, generated en/uz/ru localization, strict analysis, and focused tests.

> ✅ Verified with Flutter `3.47.5` and Dart `3.13.4`. CI pins the same Flutter version.

## ✨ Highlights

- 🧩 **Feature-first architecture** for scalable modules
- 🌊 **Riverpod** for dependency injection and state management
- 🧭 **GoRouter** for declarative navigation
- 🌐 **Dio** with typed request helpers and consistent API errors
- 🔐 **Secure token storage** with automatic legacy-token cleanup
- 📲 **Native OTP autofill** for Android and iOS verification flows
- ♻️ **Safe token refresh** with concurrent `401` request coalescing
- 🪵 **Readable debug logging** with sensitive-data redaction
- 🌍 **Generated en/uz/ru localization** that defaults to the system locale and persists the user's choice
- 🔥 **Non-blocking, optional Firebase** bootstrap
- 🔔 **Foreground local notifications** for incoming messages
- 🛡️ **Release configuration guard** that rejects placeholder or unsafe API endpoints
- 🧪 **Analyzer and test coverage** for critical infrastructure

## 🧰 Tech stack

| Area | Package |
| --- | --- |
| State management | `flutter_riverpod` |
| Navigation | `go_router` |
| Networking | `dio` |
| Localization | Flutter `gen-l10n` + `intl` |
| Local storage | `shared_preferences` (`SharedPreferencesAsync`) |
| Secure storage | `flutter_secure_storage` |
| Firebase | `firebase_core`, `firebase_messaging` |
| Notifications | `flutter_local_notifications` |

## ✅ Requirements

- Flutter `3.47.5` (pinned in CI)
- Dart `3.13.0` or newer
- Android API `24+` with compile SDK `37+`
- iOS `15.0+`
- Xcode and CocoaPods for iOS development
- Android Studio or Android SDK tools for Android development

Check your environment:

```bash
flutter doctor
flutter devices
```

## ⚡ Quick start

```bash
git clone <your-repository-url>
cd flutter-boilerplate
flutter pub get
flutter run \
  --dart-define=APP_NAME="My App" \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=API_VERSION=v1
```

The app starts without Firebase configuration and without waiting for
preferences or Firebase to load. Firebase-dependent features remain disabled
until Firebase is configured.

## ⚙️ Runtime configuration

Environment-specific values are provided through `--dart-define`; secrets should never be committed to the repository.

| Key | Default | Purpose |
| --- | --- | --- |
| `APP_NAME` | `Flutter Boilerplate` | Application name and local-storage namespace |
| `API_BASE_URL` | `https://api.example.com` | Backend base URL |
| `API_VERSION` | `v1` | API path prefix |

Example values are available in [`.env.example`](.env.example).

Release builds validate `API_BASE_URL` before launching: the URL must be an
absolute HTTPS URL and must not still be the placeholder
`https://api.example.com`. Debug and test builds keep the template defaults so a
fresh clone runs immediately.

### ▶️ Development run

```bash
flutter run \
  --dart-define=APP_NAME="My App" \
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=API_VERSION=v1
```

### 📦 Release builds

```bash
flutter build apk --release \
  --dart-define=API_BASE_URL=https://api.your-service.example \
  --dart-define=API_VERSION=v1

flutter build ios --release \
  --dart-define=API_BASE_URL=https://api.your-service.example \
  --dart-define=API_VERSION=v1
```

## 🗂️ Project structure

```text
lib/
├── app/
│   ├── router/              # GoRouter configuration
│   ├── theme/               # Material theme
│   └── app.dart             # Root application widget
├── core/
│   ├── config/              # Compile-time environment values and validation
│   ├── firebase/            # Non-blocking Firebase bootstrap and notifications
│   ├── localization/        # Locale controller, persistence seam, fallback rules
│   ├── network/             # Dio client, auth, errors, logging
│   └── storage/             # SharedPreferencesAsync and secure storage
├── features/
│   ├── auth/                # Authentication repository and OTP input
│   ├── home/                # Example home feature
│   └── settings/            # Example settings feature + locale/permission actions
├── l10n/                    # ARB sources and generated localization classes
└── main.dart                # Application bootstrap

test/
├── core/                    # Config, localization, Firebase and networking tests
├── features/                # Feature-level widget/service tests
├── support/                 # Small in-test fakes (preferences, notification settings)
└── widget_test.dart         # Application smoke tests
```

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for architecture rules and implementation details.

## 🌍 Localization

Visible starter strings come from generated `gen-l10n` resources in `lib/l10n`
(`app_en.arb`, `app_uz.arb`, `app_ru.arb`). Regenerate after editing ARB files:

```bash
flutter gen-l10n
```

- With no saved preference, the app starts in the device locale when it is
  English, Uzbek or Russian and falls back to English otherwise.
- Choosing a language in **Settings** applies immediately and is persisted with
  `SharedPreferencesAsync`.
- API requests send the active language code as `Accept-Language` on every
  request, including token refresh and uploads.

## 🌐 Networking and authentication

`ApiClient` wraps Dio and provides typed helpers for `GET`, `POST`, `PUT`, `PATCH`, `DELETE`, and multipart uploads.

The authentication interceptor:

1. Adds the current locale and bearer token to requests.
2. Detects unauthorized responses.
3. Coalesces concurrent `401` responses into one refresh operation.
4. Replays failed requests after a successful refresh.
5. Clears credentials and signals authentication failure when refresh fails.

The default refresh endpoint is:

```text
{API_BASE_URL}/{API_VERSION}/auth/refresh/
```

Debug builds include structured request and response logs. Authorization headers, tokens, passwords, cookies, and other sensitive values are redacted.

## 📲 OTP autofill

`OtpCodeField` provides a reusable six-digit input configured with Flutter's native `AutofillHints.oneTimeCode`. Android and iOS can offer a received SMS code directly above the keyboard while the field is focused.

```dart
OtpCodeField(
  onChanged: (code) {
    // Keep local form state in sync.
  },
  onCompleted: (code) {
    // Submit the complete code to your verification endpoint.
  },
)
```

Import it from:

```dart
import 'package:flutter_boilerplate/features/auth/presentation/widgets/otp_code_field.dart';
```

For reliable platform detection, the verification SMS should clearly contain one code and identify the app or domain according to the Android and Apple SMS autofill formats. The widget accepts digits only, limits input to six characters by default, supports pasted codes, and closes the autofill context without saving the OTP.

## 🔐 Storage and security

- Access and refresh tokens are stored only in platform secure storage.
- `SharedPreferencesAsync` is reserved for non-sensitive preferences such as locale.
- Legacy plaintext tokens are removed shortly after startup, off the first frame.
- Secrets and production credentials must be supplied outside source control.

## 🔥 Firebase setup

Firebase is optional and never blocks startup: `main` does not await it, and a
Riverpod `FutureProvider` initializes it when the UI first observes the status.
Missing configuration maps to an "unconfigured" status instead of failing the app.

To enable it:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Then add the generated platform configuration files required by Firebase. Once
initialized, foreground messages are displayed through
`flutter_local_notifications`.

Notification permission is **not** requested at startup. The user asks for it
explicitly with the **Enable notifications** action in Settings; denial or an
unavailable permission is reported without crashing.

## 🧪 Quality checks

Run the complete local check:

```bash
make check
```

Or run each command separately after `flutter pub get`:

```bash
flutter analyze --no-pub
flutter test --no-pub
```

Build verification:

```bash
flutter build apk --debug --no-pub
flutter build ios --simulator
```

CI runs dependency resolution, the analyzer, tests, and an Android debug build
on Linux. iOS builds remain a local macOS check.

## 🔄 Updating dependencies

```bash
flutter pub outdated
flutter pub upgrade
```

This project keeps only dependencies that serve an active feature. Prefer the
standard library or a small helper over a new package, and document any
unresolved major upgrade instead of forcing it. Review package changelogs before
major migrations:

```bash
flutter pub upgrade --major-versions
flutter analyze --no-pub
flutter test --no-pub
```

## 🏷️ Rename for a new app

After creating a project from this template:

1. Update `name`, `description`, and `version` in `pubspec.yaml`.
2. Change the Android `namespace` and `applicationId` in `android/app/build.gradle.kts`.
3. Change the iOS bundle identifier in Xcode.
4. Replace app icons and launch assets.
5. Set your runtime configuration values.
6. Run `flutterfire configure` if Firebase is required.
7. Run analyzer, tests, and platform builds before the first commit.

A helper script is also available:

```bash
./scripts/rename_app.sh
```

Review its changes before committing.

## 🧹 Useful commands

```bash
make bootstrap   # Install dependencies
make analyze     # Run static analysis
make test        # Run tests
make check       # Install, analyze, and test
make clean       # Clean and reinstall dependencies
```

## 🤝 Contribution workflow

1. Create a focused branch.
2. Keep changes inside the responsible feature or core module.
3. Add or update focused tests.
4. Run `make check`.
5. Verify the affected Android or iOS build.
6. Open a review with a concise explanation of behavior changes.
