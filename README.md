# 2048

A Flutter 2048 game built on [flutter-boilerplate](https://github.com/ExcuseMeBro/flutter-boilerplate). It keeps the boilerplate's hardened foundation — GoRouter, Riverpod, secure storage, generated en/uz/ru localization and optional Firebase — and adds the game on top of it.

## Run

```bash
flutter pub get
flutter run
```

Check the project with `flutter analyze && flutter test`.

## How to play

- Swipe the board in any direction, or use the arrow keys or WASD. Merge matching tiles to reach 2048.
- Each valid move spawns a 2 or 4. A tile can merge only once per move.
- **Undo** restores the last move. **New game** asks for confirmation before replacing the current game.
- Your current game, score, and best score are saved on your device. You can keep playing after reaching 2048.
- Animations respect the device's reduced-motion setting. Moves provide gentle haptic feedback.
- Tap **Developed by Bro** at the bottom of the game to open [brodev.uz](https://brodev.uz) in your browser.

## Android release signing

The release App Bundle is signed with the local upload key in `android/app/upload-keystore.jks` using `android/key.properties`. Both files are ignored by Git. Build it with:

```bash
flutter build appbundle --release
```

The signed bundle is at `build/app/outputs/bundle/release/app-release.aab`. **Back up both signing files in a secure, separate location before publishing.** Keep the passwords private; losing the upload key may prevent future updates without a Play Console key reset. Never commit either file or share `key.properties` publicly.

## Project structure

- `lib/features/game/game_engine.dart` — game rules, spawning, undo, and save-state serialization.
- `lib/features/home/home_page.dart` — game UI, animations, touch and keyboard controls.
- `lib/app/theme/app_theme.dart` — shared colors, spacing, and light/dark themes.
- `lib/features/settings/settings_page.dart` — language and notification actions.
- `lib/core/` — config, storage, networking, localization and Firebase seams.
- `scripts/generate_icons.py` — regenerates iOS and Android launcher icons using Pillow (`python3 scripts/generate_icons.py`).

## Localization

Visible starter strings come from generated `gen-l10n` resources in `lib/l10n` (`app_en.arb`, `app_uz.arb`, `app_ru.arb`). Regenerate after editing ARB files:

```bash
flutter gen-l10n
```

With no saved preference the app follows the device locale when it is English, Uzbek or Russian and falls back to English otherwise. The choice made in **Settings** applies immediately and is persisted with `SharedPreferencesAsync`.

## Storage and security

- Access and refresh tokens are stored only in platform secure storage.
- `SharedPreferencesAsync` is reserved for non-sensitive preferences such as locale and the saved game.
- Legacy plaintext tokens are removed shortly after startup, off the first frame.
- Secrets and production credentials must be supplied outside source control.

## Firebase (optional)

Firebase never blocks startup; status is shown in Settings and notification permission is only requested from the **Enable notifications** action.

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

## Quality checks

```bash
make check
```

Or each command separately:

```bash
flutter analyze --no-pub
flutter test --no-pub
```

Run analyzer, tests, and platform builds locally before opening a PR.

## Rename for a new app

1. Update `name`, `description`, and `version` in `pubspec.yaml`.
2. Change the Android `namespace` and `applicationId` in `android/app/build.gradle.kts`.
3. Change the iOS bundle identifier in Xcode.
4. Replace app icons and launch assets.
5. Set runtime configuration values from [`.env.example`](.env.example).
6. Run analyzer, tests, and platform builds before the first commit.
