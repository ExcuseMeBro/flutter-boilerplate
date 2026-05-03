#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "Usage: scripts/rename_app.sh <app_name> <bundle_id>" >&2
  echo "Example: scripts/rename_app.sh MyApp com.example.myapp" >&2
  exit 1
fi

APP_NAME="$1"
BUNDLE_ID="$2"
APP_SLUG=$(printf '%s' "$APP_NAME" | tr '[:upper:] -' '[:lower:]__' | tr -cd 'a-z0-9_')
ANDROID_PATH="${BUNDLE_ID//./\/}"

python3 - <<PY
from pathlib import Path
replacements = {
    'Flutter Boilerplate': '$APP_NAME',
    'flutter_boilerplate': '$APP_SLUG',
    'uz.bro.flutter_boilerplate': '$BUNDLE_ID',
}
for file in [
    Path('pubspec.yaml'),
    Path('README.md'),
    Path('android/app/src/main/AndroidManifest.xml'),
    Path('android/app/build.gradle.kts'),
]:
    text = file.read_text()
    for old, new in replacements.items():
        text = text.replace(old, new)
    file.write_text(text)
PY

mkdir -p "android/app/src/main/kotlin/$ANDROID_PATH"
if [[ -f android/app/src/main/kotlin/uz/bro/flutter_boilerplate/MainActivity.kt ]]; then
  mv android/app/src/main/kotlin/uz/bro/flutter_boilerplate/MainActivity.kt "android/app/src/main/kotlin/$ANDROID_PATH/MainActivity.kt"
  python3 - <<PY
from pathlib import Path
file = Path('android/app/src/main/kotlin/$ANDROID_PATH/MainActivity.kt')
file.write_text(file.read_text().replace('package uz.bro.flutter_boilerplate', 'package $BUNDLE_ID'))
PY
fi

echo "Renamed Android package. Update iOS bundle ID in Xcode if needed."
