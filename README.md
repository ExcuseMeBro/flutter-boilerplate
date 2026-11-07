# Flutter starter

A reusable Android/iOS starter with Riverpod, GoRouter, Dio authentication,
platform secure storage, English/Uzbek/Russian localization and optional Firebase.
The default screen introduces the starter and opens Settings; it has no product-specific behavior.

## Quick start

Use Flutter **3.47.9** (Dart 3.13.7), Python **3.9+** for bootstrap/tests and
JDK **21** for Android builds. Android SDK/platform tools and the SDK requested
by Gradle must be installed; iOS needs macOS, Xcode and CocoaPods.

```bash
python3 scripts/bootstrap.py --name my_app --application-id com.example.myapp --dry-run
python3 scripts/bootstrap.py --name my_app --application-id com.example.myapp
flutter pub get --enforce-lockfile
flutter run
```

The dependency-free script renames the Dart package/imports, localized app title,
Android namespace/application/activity package, iOS bundle IDs (including tests)
and the public `.env.example` app name. `--name` is required, lower_snake_case,
non-reserved and at most 64 characters. `--application-id` is optional: lowercase
reverse-domain segments, non-reserved, at most 150 characters; omitted means
**preserve the current ID**. Run it from any directory. Repeating the same options
is a no-op; dry-run only prints planned paths. It validates all targets before
writing and rejects symlinks, escaping paths and activity destination collisions.
Run on a trusted, idle checkout with a clean Git backup (writes are not transactional
against concurrent filesystem changes or disk failure).

It never reads or overwrites `.env`, signing keys, Firebase credentials or other
secret files, never creates secrets, installs dependencies or executes shell input.
Configure private files yourself and replace the generic launcher icons before publishing.
When changing the app title on an existing installation, its namespaced locale
preference starts fresh; this tool is intended for new projects.

## Configuration

[`.env.example`](.env.example) documents public defaults. `.env` is **not** loaded
automatically. Supply values with Flutter's `--dart-define` options, for example:

```bash
flutter run --dart-define=API_BASE_URL=https://api.your-domain.test/v1/
```

Release startup requires a non-placeholder HTTPS API URL. Dart defines are embedded
in the app, **not a place for private server credentials**. Never commit production
secrets. Firebase is optional: absent configuration is reported in Settings and
never blocks the first frame. Add platform configuration with FlutterFire when
needed; notification permission is requested only by the Settings action.

## Structure

- `lib/features/home/` — generic entrypoint; `lib/features/settings/` — language and notification actions.
- `lib/features/auth/` — reusable auth repository.
- `lib/core/` — config, networking, secure storage, localization and Firebase seams.
- `lib/app/` — shared Material theme and router.
- `lib/l10n/` — ARB sources and committed generated translations (`flutter gen-l10n`).
- `scripts/bootstrap.py` — safe rename CLI; `scripts/test_bootstrap.py` — temporary-copy checks.

## Storage and request performance

Tokens remain exclusively in platform secure storage. Preferences contain only
non-sensitive data; legacy plaintext tokens are purged after startup. Concurrent
reads share only an **in-flight** storage operation, not a persistent token/locale
cache. Login, refresh, logout and language writes invalidate in-flight values and
serialize writes; later reads reload storage. External changes are observed on the
next non-overlapping read. See [request profiling](docs/REQUEST_STORAGE_PROFILE.md)
for the repeatable synthetic baseline, final measurements and limitations.

## Checks and CI

```bash
make check
# Equivalent individual gates:
flutter pub get --enforce-lockfile
flutter analyze --no-pub
flutter test --no-pub
python3 -m unittest discover -s scripts -p 'test_*.py' -v
flutter build apk --debug --no-pub
# On macOS with Xcode/CocoaPods:
flutter build ios --simulator --debug --no-pub
```

[GitHub Actions](.github/workflows/ci.yml) runs on pull requests and pushes to `dev`:
locked dependencies, analyze, all Flutter tests, bootstrap tests and an Android
debug build. Action revisions and Flutter/JDK versions are pinned; the pub cache
key includes OS, Flutter version and lockfile hash. Jobs have a read-only token,
no production secrets and no signing/publishing step; any failed gate fails CI.
iOS is a local platform check, not part of the Linux CI job.

If Flutter selects Android Studio's JDK 25 instead of JDK 21, select JDK 21 in your
local Flutter configuration (`flutter config --jdk-dir=/path/to/jdk21`) or set
`GRADLE_OPTS=-Dorg.gradle.java.home=/path/to/jdk21` for the build. Do not commit local
SDK/JDK paths. The pinned Gradle/AGP/Kotlin versions currently emit future-support
warnings; changing them is a separate upgrade, not a reason to bypass validation.

## Android release signing

Debug builds need no private files. Release builds deliberately fail if
`android/key.properties` is missing; they never fall back to a debug signing key.
Provide a private upload keystore and `storeFile`, `storePassword`, `keyAlias`,
`keyPassword` in the ignored properties file, then:

```bash
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.your-domain.test/v1/
```

Back up signing material securely. Release signing, store publication and real
Firebase/backend integration are not exercised by starter CI.
