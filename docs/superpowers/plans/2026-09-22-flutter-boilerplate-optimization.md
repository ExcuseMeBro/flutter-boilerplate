# Flutter Boilerplate Optimization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Follow the OpenSpec apply tasks in order with test-driven development. This repository's parent workflow uses one Paseo worker rather than one fresh subagent per task; do not delegate.

**Goal:** Deliver a smaller, reproducible Flutter starter with persisted system-default en/uz/ru localization, non-blocking optional Firebase, user-triggered notification authorization, and safe release configuration.

**Architecture:** Flutter `gen-l10n` owns visible strings. A Riverpod async locale controller persists a supported locale through `SharedPreferencesAsync`, while networking reads the same persisted value for `Accept-Language`. Firebase status moves behind a single FutureProvider so the first frame is not blocked, and release configuration is checked through a pure validation seam before `runApp`.

**Tech Stack:** Flutter 3.47.5, Dart 3.13, Riverpod 3, GoRouter, Dio, SharedPreferencesAsync, Firebase Core/Messaging, flutter_local_notifications, Flutter gen-l10n.

---

## File Map

**Create**
- `l10n.yaml` — source-tree localization generation settings.
- `lib/l10n/app_en.arb`, `lib/l10n/app_uz.arb`, `lib/l10n/app_ru.arb` — all starter UI strings.
- `lib/core/localization/locale_controller.dart` — supported-locale normalization, persistence, and Riverpod state.
- `test/core/localization/locale_controller_test.dart` — system fallback and persistence tests.
- `test/core/config/app_config_test.dart` — release API validation tests.

**Modify**
- `lib/main.dart` — validate configuration, stop awaiting preferences/Firebase, then run the provider scope.
- `lib/app/app.dart` — watch locale and async Firebase providers; use generated delegates/locales.
- `lib/core/config/app_config.dart` — pure release validation.
- `lib/core/storage/local_storage.dart` — SharedPreferencesAsync, async locale lookup, legacy-token purge.
- `lib/core/network/auth_interceptor.dart` and tests — await locale and prove header updates.
- `lib/core/firebase/firebase_bootstrap.dart` — one FutureProvider and optional failure state.
- `lib/core/firebase/push_notification_service.dart` — initialize listeners/channels without prompting; expose permission request.
- `lib/features/home/home_page.dart`, `lib/features/settings/settings_page.dart` — generated strings, async Firebase state, locale control and notification action.
- `test/widget_test.dart` plus focused Firebase/settings tests — first-frame, translation, selection, and permission behavior.
- `pubspec.yaml`, `pubspec.lock` — remove unused packages and upgrade retained compatible versions.
- `.github/workflows/ci.yml` — pin Flutter and build Android debug.
- `README.md`, `docs/ARCHITECTURE.md` — document actual behavior.
- `openspec/changes/optimize-flutter-boilerplate/tasks.md` — mark each completed task immediately.

## Task 1: Preserve the User's WIP Baseline

- [x] **Step 1: Record the primary status and hashes**

Run from the parent-owned shell, not the worker:

```bash
git -C /Users/bro/PROJECTS/flutter-boilerplate status --porcelain=v1 > "$EVIDENCE/primary-status.before"
git -C /Users/bro/PROJECTS/flutter-boilerplate diff --binary > "$EVIDENCE/primary-wip.patch"
```

Archive only non-`.todos` untracked files (`ios/Podfile.lock`, OTP widget and OTP test) into private evidence. Do not stash, reset, checkout, add, or commit in the primary checkout.

- [x] **Step 2: Apply copies in the task worktree**

```bash
git apply "$EVIDENCE/primary-wip.patch"
tar -xzf "$EVIDENCE/primary-untracked.tar.gz" -C /Users/bro/.paseo/worktrees/3ur59dwk/optimize-flutter-boilerplate
```

Expected: the copied tracked/untracked source appears only in the task worktree; `.todos/` does not.

- [x] **Step 3: Prove the primary is unchanged**

```bash
git -C /Users/bro/PROJECTS/flutter-boilerplate status --porcelain=v1 > "$EVIDENCE/primary-status.after-copy"
cmp "$EVIDENCE/primary-status.before" "$EVIDENCE/primary-status.after-copy"
```

Expected: `cmp` exits 0.

- [x] **Step 4: Run baseline checks**

```bash
flutter analyze --no-pub
flutter test --no-pub
```

Expected: analyzer clean and all existing tests pass before new behavior is introduced.

- [x] **Step 5: Commit the copied baseline separately**

```bash
git add README.md analysis_options.yaml android ios pubspec.yaml pubspec.lock lib/features/auth/presentation test/features/auth/presentation
git commit -m "chore: preserve current Flutter boilerplate updates"
```

## Task 2: Locale Resolution and Persistence (TDD)

- [x] **Step 1: Write failing locale tests**

Create `test/core/localization/locale_controller_test.dart` covering this public seam:

```dart
expect(normalizeLocale(const Locale('uz', 'UZ')), const Locale('uz'));
expect(normalizeLocale(const Locale('de')), const Locale('en'));

final store = FakeLocaleStore(savedCode: 'ru');
final controller = LocaleController(store: store, platformLocale: const Locale('uz'));
expect(await controller.build(), const Locale('ru'));
await controller.setLocale(const Locale('en'));
expect(store.savedCode, 'en');
```

Use a tiny in-test fake implementing the locale-store interface; no mocking package.

- [x] **Step 2: Verify RED**

```bash
flutter test --no-pub test/core/localization/locale_controller_test.dart
```

Expected: compilation/test failure because localization controller and store seam do not exist.

- [x] **Step 3: Implement the minimum locale seam**

Create `lib/core/localization/locale_controller.dart` with:

```dart
const supportedLocales = [Locale('en'), Locale('uz'), Locale('ru')];

Locale normalizeLocale(Locale locale) => supportedLocales.firstWhere(
  (candidate) => candidate.languageCode == locale.languageCode,
  orElse: () => const Locale('en'),
);

abstract interface class LocaleStore {
  Future<String?> readLocaleCode();
  Future<void> writeLocaleCode(String code);
}
```

Implement `LocaleController` as an `AsyncNotifier<Locale>` using the platform locale when no valid saved code exists and persisting before exposing an explicit selection. Provide an overrideable platform-locale provider for tests.

- [x] **Step 4: Migrate local storage**

`LocalStorage` receives `SharedPreferencesAsync`, implements `LocaleStore`, makes `getLocaleCode()` asynchronous, and preserves `purgeLegacyTokens()`. The provider constructs `SharedPreferencesAsync()` directly; `main` no longer obtains/overrides a legacy instance.

- [x] **Step 5: Verify GREEN and commit**

```bash
flutter test --no-pub test/core/localization/locale_controller_test.dart test/core/network/auth_interceptor_test.dart
```

Expected: locale tests pass; update existing storage test assertions to await async reads.

```bash
git add lib/core/localization lib/core/storage test/core/localization test/core/network/auth_interceptor_test.dart
git commit -m "feat: persist the active locale"
```

## Task 3: Generated en/uz/ru UI

- [x] **Step 1: Add localization inputs**

Create `l10n.yaml`:

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
```

Add matching ARB keys for app title, Home card/status/action labels, Settings labels, Firebase loading/ready/unconfigured states, locale names, notification action/results, and FCM token results.

- [x] **Step 2: Generate and verify outputs**

```bash
flutter gen-l10n
```

Expected: `lib/l10n/app_localizations.dart` and locale subclasses are generated successfully.

- [x] **Step 3: Write failing widget tests**

Update `test/widget_test.dart` to override locale storage and Firebase status, then assert English text. Add a Settings test that selects Uzbek and asserts an Uzbek heading/action appears after `pumpAndSettle`.

```bash
flutter test --no-pub test/widget_test.dart
```

Expected: FAIL before MaterialApp and pages consume generated localizations.

- [x] **Step 4: Connect MaterialApp and screens**

`BoilerplateApp` uses `AppLocalizations.localizationsDelegates`, `AppLocalizations.supportedLocales`, and `locale: localeAsync.valueOrNull ?? normalizeLocale(platformLocale)`. Home and Settings read `AppLocalizations.of(context)!`; Settings uses a native `DropdownButtonFormField<Locale>` or equivalent three-option control and calls the locale notifier.

- [x] **Step 5: Verify and commit**

```bash
flutter test --no-pub test/widget_test.dart
```

Expected: translated widget assertions pass.

```bash
git add l10n.yaml lib/l10n lib/app/app.dart lib/features/home lib/features/settings test/widget_test.dart
git commit -m "feat: add persisted app localization"
```

## Task 4: API Locale Header (TDD)

- [x] **Step 1: Add the failing changed-locale assertion**

In `auth_interceptor_test.dart`, save `uz` through the async locale store, send a request, and assert:

```dart
expect(sent.headers['Accept-Language'], 'uz');
```

- [x] **Step 2: Verify RED**

```bash
flutter test --no-pub test/core/network/auth_interceptor_test.dart --plain-name "uses the persisted active locale"
```

Expected: FAIL because the interceptor still assumes synchronous legacy storage or defaults to English.

- [x] **Step 3: Await locale lookup in `onRequest`**

```dart
options.headers['Accept-Language'] = await _localStorage.getLocaleCode();
```

Keep auth, refresh, replay, and skip-auth behavior unchanged.

- [x] **Step 4: Verify and commit**

```bash
flutter test --no-pub test/core/network/auth_interceptor_test.dart
```

Expected: all interceptor/storage tests pass.

```bash
git add lib/core/network/auth_interceptor.dart test/core/network/auth_interceptor_test.dart
git commit -m "feat: send the selected API locale"
```

## Task 5: Non-Blocking Firebase and Explicit Permission (TDD)

- [x] **Step 1: Write failing UI/bootstrap tests**

Override `firebaseStatusProvider` with a pending `Completer<FirebaseStatus>().future`, pump the app once, and assert the Home page plus localized Firebase loading label are visible. Add a service seam/callback test proving `PushNotificationService.initialize()` does not invoke permission authorization.

- [x] **Step 2: Verify RED**

```bash
flutter test --no-pub test/widget_test.dart test/core/firebase
```

Expected: current synchronous provider shape or startup permission behavior fails the new assertions.

- [x] **Step 3: Implement async status and split permission**

```dart
final firebaseStatusProvider = FutureProvider<FirebaseStatus>((ref) {
  return FirebaseBootstrap.initialize();
});
```

`main` no longer awaits Firebase. `PushNotificationService.initialize()` configures the plugin/channel/listener only. Add `requestPermission()` returning `NotificationSettings`; Settings invokes it only from the localized enable-notifications action and handles denial/unavailability with a localized SnackBar.

- [x] **Step 4: Keep token and foreground flows**

Retain `getToken()` and `_showForegroundNotification`. Disable notification/token actions unless Firebase status has configured data. Do not add navigation/deep-link behavior.

- [x] **Step 5: Verify and commit**

```bash
flutter test --no-pub test/widget_test.dart test/core/firebase
```

Expected: first-frame, no-startup-prompt, permission outcome, token, and foreground behavior tests pass.

```bash
git add lib/main.dart lib/core/firebase lib/features/home lib/features/settings test
git commit -m "feat: initialize Firebase without blocking startup"
```

## Task 6: Release Configuration Validation (TDD)

- [x] **Step 1: Write failing pure unit tests**

Create `test/core/config/app_config_test.dart` against:

```dart
AppConfig.validate(apiBaseUrl: value, isRelease: mode);
```

Cover placeholder/release throws, malformed/release throws, HTTP/release throws, valid HTTPS/release succeeds, and placeholder/debug succeeds.

- [x] **Step 2: Verify RED**

```bash
flutter test --no-pub test/core/config/app_config_test.dart
```

Expected: FAIL because `validate` does not exist.

- [x] **Step 3: Implement minimal validation**

Parse with `Uri.tryParse`; when `isRelease` require scheme `https`, non-empty host, and host not `api.example.com`. Throw `StateError` with a message naming `API_BASE_URL`. Call `AppConfig.validate(apiBaseUrl: AppConfig.apiBaseUrl, isRelease: kReleaseMode)` before `runApp`.

- [x] **Step 4: Verify and commit**

```bash
flutter test --no-pub test/core/config/app_config_test.dart
```

Expected: all five cases pass.

```bash
git add lib/core/config/app_config.dart lib/main.dart test/core/config/app_config_test.dart
git commit -m "feat: reject unsafe release API configuration"
```

## Task 7: Dependency and CI Cleanup

- [x] **Step 1: Remove unused dependencies**

Delete only `equatable`, `connectivity_plus`, `json_annotation`, `url_launcher`, and `cupertino_icons` from `pubspec.yaml`. Keep `intl` and active packages.

- [x] **Step 2: Upgrade and inspect**

```bash
flutter pub upgrade
flutter pub outdated
```

Expected: retained compatible direct packages are upgraded; any unresolved major is documented rather than forced.

- [x] **Step 3: Pin CI and build**

Set `flutter-version: '3.47.5'` in `subosito/flutter-action`; keep cache. Use `--no-pub` for analyze/test after the install step and add:

```yaml
- name: Build Android debug
  run: flutter build apk --debug --no-pub
```

- [x] **Step 4: Update documentation and commit**

Document generated localization, default-system/persisted locale, explicit notification permission, release HTTPS define requirement, dependency update policy, and Linux CI/iOS local build split.

```bash
git add pubspec.yaml pubspec.lock .github/workflows/ci.yml README.md docs/ARCHITECTURE.md
git commit -m "chore: update Flutter dependencies and CI"
```

## Task 8: Final Verification and OpenSpec Completion

- [x] **Step 1: Run exact final checks**

```bash
flutter gen-l10n
flutter analyze --no-pub
flutter test --no-pub
flutter build apk --debug --no-pub
```

Expected: every command exits 0; test output reports all tests passed; APK build reports the output path.

- [x] **Step 2: Check dependency and source hygiene**

```bash
flutter pub outdated
git diff --check
git status --short
git grep -nE 'package:(equatable|connectivity_plus|json_annotation|url_launcher|cupertino_icons)/' -- lib test
```

Expected: no removed-package imports, no whitespace errors, and only intended task files differ from the task base.

- [x] **Step 3: Prove the primary checkout stayed unchanged**

Capture status/hash evidence again and compare it with the before-copy evidence. Any difference not created by the user during execution is BLOCKED; never reset the primary.

- [x] **Step 4: Mark OpenSpec tasks complete and validate**

Update each completed checkbox in `openspec/changes/optimize-flutter-boilerplate/tasks.md`, then run:

```bash
openspec validate optimize-flutter-boilerplate --strict
openspec status --change optimize-flutter-boilerplate
```

Expected: valid change, 16/16 tasks complete.

- [x] **Step 5: Commit final bookkeeping**

```bash
git add openspec/changes/optimize-flutter-boilerplate/tasks.md docs/superpowers/plans/2026-09-22-flutter-boilerplate-optimization.md
git commit -m "docs: complete Flutter optimization plan"
```

- [ ] **Step 6: Parent review**

The parent inspects the full diff and raw check evidence. Because the selected workflow classified the cross-module startup/configuration work as guarded, obtain a fresh source-current independent review and formal acceptance before any delivery. Do not push or mutate main from the worker.
