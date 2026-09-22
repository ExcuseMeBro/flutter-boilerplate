## 1. Preserve and Reproduce the Current Baseline

- [x] 1.1 Capture the primary checkout's tracked diff and non-`.todos` untracked source files into private task evidence, apply copies to the isolated worktree, and verify the primary status and file hashes are unchanged.
- [x] 1.2 Run the existing analyzer and focused/full tests on the copied baseline and record the results before optimization.

## 2. Localize and Persist the Application Locale

- [x] 2.1 Add failing focused tests for supported/unsupported system-locale fallback, saved-locale restoration, and persistence after selection; verify each fails for the missing behavior.
- [x] 2.2 Add `gen-l10n` configuration and en/uz/ru ARB resources, implement the Riverpod locale controller with `SharedPreferencesAsync`, and verify the locale tests pass.
- [x] 2.3 Replace starter-screen hardcoded strings and add the Settings locale control; verify widget tests render and switch at least English and Uzbek translations.
- [x] 2.4 Add a failing request-header test for a changed locale, update local storage/networking to use the persisted active locale, and verify the Dio interceptor test passes with `Accept-Language: uz`.

## 3. Make Firebase and Notifications Non-Blocking

- [x] 3.1 Add failing tests proving Firebase status can remain loading while the core UI renders and startup does not request notification permission.
- [x] 3.2 Move Firebase bootstrap to a non-auto-disposed FutureProvider, remove Firebase/SharedPreferences awaits from `main`, and verify the non-blocking UI test passes.
- [x] 3.3 Move notification authorization behind the localized Settings action while retaining foreground listener/channel setup and token retrieval; verify focused service/widget tests cover denied/unavailable outcomes.

## 4. Enforce Safe Release Configuration

- [x] 4.1 Add failing unit tests for placeholder, malformed, non-HTTPS, valid HTTPS, and debug-default API configurations.
- [x] 4.2 Implement the pure release validation seam and call it before `runApp`; verify all configuration tests pass.

## 5. Clean Dependencies and Reproducible Tooling

- [x] 5.1 Remove unused `equatable`, `connectivity_plus`, `json_annotation`, `url_launcher`, and `cupertino_icons`, upgrade retained compatible dependencies, and verify `flutter pub outdated` shows no compatible direct upgrade left unintentionally.
- [x] 5.2 Pin Flutter 3.47.5 in CI and add the Android debug build smoke step; verify workflow syntax and run the equivalent local commands.
- [x] 5.3 Update README and architecture documentation for localization, Firebase permission timing, release defines, dependency policy, and quality commands; verify documented paths and commands exist.

## 6. Final Verification and Review

- [x] 6.1 Run generated localization, `flutter analyze --no-pub`, `flutter test --no-pub`, and `flutter build apk --debug --no-pub`; inspect raw results and keep the worktree clean apart from intended changes.
- [x] 6.2 Review the full diff against all three capability specs and the copied WIP baseline, confirm the primary checkout stayed unchanged, and obtain the required source-current review/acceptance verdict before delivery.
