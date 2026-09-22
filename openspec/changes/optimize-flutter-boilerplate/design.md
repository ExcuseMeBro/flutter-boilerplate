## Context

See `proposal.md` for motivation and the three capability specs for observable behavior. The current app initializes SharedPreferences and Firebase before `runApp`, stores a locale string that is not connected to MaterialApp, hardcodes visible English strings, and requests provisional notification permission during Firebase bootstrap. The current primary checkout also contains user-owned uncommitted platform/package/documentation and OTP work; it must be copied read-only into this isolated branch during apply and must never be stashed or modified in place.

## Goals / Non-Goals

**Goals:**
- Keep the starter's existing Riverpod, GoRouter, Dio, secure-storage, Firebase, and local-notification seams.
- Make locale, startup, notification authorization, and release configuration behavior directly testable.
- Reduce direct dependencies and keep CI reproducible without introducing another framework.

**Non-Goals:**
- Add authentication screens, flavors, offline databases, API model generation, Retrofit, Freezed, GetIt, Talker, or crash analytics.
- Change token-storage or token-refresh semantics.
- Remove Firebase or require Firebase configuration for core application use.
- Mutate or clean the user's primary checkout.

## Decisions

### Use Flutter `gen-l10n` and ARB files

Flutter's built-in generator will produce the localization API from English, Uzbek, and Russian ARB files. MaterialApp will use the generated delegates and locales, and all starter-screen strings will come from that API. This avoids `easy_localization` and keeps localization aligned with Flutter tooling.

Alternative considered: retain hardcoded strings and only set `supportedLocales`. Rejected because it does not provide localization.

### Represent locale as a Riverpod `AsyncNotifier`

A locale controller will expose the saved locale when available and use a normalized platform locale as its immediate fallback while preferences load. Selection writes through `SharedPreferencesAsync`, updates MaterialApp, and is also read by networking for `Accept-Language`. Invalid stored values fall back through the same system-locale rule.

Alternative considered: rebuild the Dio client whenever locale changes. Rejected because replacing a live client can discard interceptor state; reading the lightweight persisted locale per request is simpler and preserves the client.

### Remove only dependencies with no current responsibility

Retain `intl` for generated localization and retain every package serving an active feature. Remove unused `equatable`, `connectivity_plus`, `json_annotation`, `url_launcher`, and `cupertino_icons`; do not replace them. Upgrade retained packages only to versions resolvable by the pinned Flutter/Dart toolchain.

Alternative considered: add Freezed/json_serializable and Retrofit. Rejected because the starter has too few models/endpoints to justify generated-code complexity.

### Move Firebase into a non-blocking FutureProvider

`main` will perform only synchronous Flutter/system setup before `runApp`. A non-auto-disposed FutureProvider will initialize Firebase once when the UI observes status. Missing configuration maps to the existing unconfigured status instead of failing the app. Notification channel/listener setup remains part of successful initialization, but permission requesting moves to an explicit service method invoked from Settings.

Alternative considered: defer Firebase until the user opens Settings. Rejected because foreground messaging should be ready for configured applications without requiring navigation.

### Validate release configuration at the trust boundary

A small AppConfig validation method will reject placeholder, malformed, and non-HTTPS API URLs only in release mode. It runs before `runApp`; debug and tests retain template defaults. Tests will inject the release decision into a pure validation seam instead of depending on compile-time build mode.

Alternative considered: rely on README instructions. Rejected because documentation cannot prevent a misconfigured release.

### Pin and exercise the supported build in CI

CI will pin Flutter 3.47.5, run dependency resolution, analyzer, tests, and an Android debug build. iOS build remains a documented local/macOS check because the existing CI runner is Linux.

## Risks / Trade-offs

- [Generated localization files or imports differ across Flutter versions] → Pin Flutter in CI and use source-tree generation supported by the pinned version.
- [Async locale hydration briefly uses the system locale before applying a saved override] → Keep the bootstrap screen minimal and make the controller's loading fallback deterministic; tests cover restoration.
- [Reading locale storage for each API request adds asynchronous work] → The operation is a small platform preference read; avoid a second mutable cache until profiling demonstrates need.
- [Lazy Firebase status can be loading on the first screen] → Render an explicit localized loading status and keep all non-Firebase UI usable.
- [Release validation may surprise template users] → Limit enforcement to release mode and document the required dart-define.
- [Dependency upgrades introduce platform changes] → Upgrade in one lockfile operation and verify analyze, tests, Android build, and relevant iOS configuration files.

## Migration Plan

1. Preserve the current primary WIP as a private patch/archive and apply a copy to this isolated worktree.
2. Add failing focused tests for locale fallback/persistence/header behavior, release validation, and non-blocking Firebase/permission behavior where plugin seams permit.
3. Implement localization and locale persistence, then Firebase/permission changes.
4. Remove unused dependencies, upgrade retained dependencies, regenerate the lockfile and generated localization output.
5. Update CI and documentation; run analyzer, tests, and Android debug build.
6. Review the full diff against both the approved specs and the copied WIP baseline. Deliver only from the isolated branch after the separate history-rewrite dependency is resolved.

Rollback is the task branch before integration; the primary checkout remains untouched throughout.
