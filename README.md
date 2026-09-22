# 🚀 Flutter Boilerplate

A clean, production-ready Flutter starter for building mobile apps faster. It ships with routing, state management, networking, secure authentication storage, optional Firebase messaging, local notifications, strict analysis, and focused tests.

> ✅ Verified with Flutter `3.47.2` and Dart `3.13.2`.

## ✨ Highlights

- 🧩 **Feature-first architecture** for scalable modules
- 🌊 **Riverpod** for dependency injection and state management
- 🧭 **GoRouter** for declarative navigation
- 🌐 **Dio** with typed request helpers and consistent API errors
- 🔐 **Secure token storage** with automatic legacy-token cleanup
- 📲 **Native OTP autofill** for Android and iOS verification flows
- ♻️ **Safe token refresh** with concurrent `401` request coalescing
- 🪵 **Readable debug logging** with sensitive-data redaction
- 🔥 **Optional Firebase** bootstrap and Cloud Messaging support
- 🔔 **Foreground local notifications** for incoming messages
- 🌍 **Localization-ready** Flutter configuration
- 🧪 **Analyzer and test coverage** for critical infrastructure

## 🧰 Tech stack

| Area | Package |
| --- | --- |
| State management | `flutter_riverpod` |
| Navigation | `go_router` |
| Networking | `dio`, `connectivity_plus` |
| Local storage | `shared_preferences` |
| Secure storage | `flutter_secure_storage` |
| Firebase | `firebase_core`, `firebase_messaging` |
| Notifications | `flutter_local_notifications` |
| Models and utilities | `equatable`, `json_annotation`, `intl` |

## ✅ Requirements

- Flutter `3.44.0` or newer
- Dart `3.12.0` or newer
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

The app can start without Firebase configuration. Firebase-dependent features remain disabled until Firebase is configured.

## ⚙️ Runtime configuration

Environment-specific values are provided through `--dart-define`; secrets should never be committed to the repository.

| Key | Default | Purpose |
| --- | --- | --- |
| `APP_NAME` | `Flutter Boilerplate` | Application name and local-storage namespace |
| `API_BASE_URL` | `https://api.example.com` | Backend base URL |
| `API_VERSION` | `v1` | API path prefix |

Example values are available in [`.env.example`](.env.example).

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
  --dart-define=API_BASE_URL=https://api.example.com \
  --dart-define=API_VERSION=v1

flutter build ios --release \
  --dart-define=API_BASE_URL=https://api.example.com \
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
│   ├── config/              # Compile-time environment values
│   ├── firebase/            # Firebase bootstrap and notifications
│   ├── network/             # Dio client, auth, errors, logging
│   └── storage/             # SharedPreferences and secure storage
├── features/
│   ├── auth/                # Authentication repository and OTP input
│   ├── home/                # Example home feature
│   └── settings/            # Example settings feature
└── main.dart                # Application bootstrap

test/
├── core/network/            # Networking and auth tests
└── widget_test.dart         # Application smoke test
```

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for architecture rules and implementation details.

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
- SharedPreferences is reserved for non-sensitive preferences such as locale.
- Legacy plaintext tokens are removed safely during application startup.
- Secrets and production credentials must be supplied outside source control.

## 🔥 Firebase setup

Firebase is optional. To enable it:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Then add the generated platform configuration files required by Firebase. Without them, the bootstrap catches the initialization error and allows the rest of the app to continue running.

Foreground Firebase messages are displayed through `flutter_local_notifications` after notification initialization succeeds.

## 🧪 Quality checks

Run the complete local check:

```bash
make check
```

Or run each command separately:

```bash
flutter pub get
flutter analyze
flutter test
```

Build verification:

```bash
flutter build apk --debug
flutter build ios --simulator
```

## 🔄 Updating dependencies

```bash
flutter pub outdated
flutter pub upgrade
```

For major-version migrations, review package changelogs before applying:

```bash
flutter pub upgrade --major-versions
flutter analyze
flutter test
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
