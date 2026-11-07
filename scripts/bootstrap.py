#!/usr/bin/env python3
"""Rename the starter using only the Python standard library; never read secrets."""
import argparse
import json
from pathlib import Path
import re
import sys

# Reserved Dart/Java/Kotlin identifiers cannot be package path components.
RESERVED = set("""abstract as assert async await base boolean break byte case catch
char class const continue covariant default deferred do double dynamic else enum
export extends extension external factory false final finally float for Function
fun get hide if implements import in inline int interface internal is late library
long mixin native new null object of on operator out override package part private
protected public rethrow return sealed set short show static strictfp super switch
synchronized sync this throw throws transient true try typedef var void volatile
when while with yield""".split())


def safe(root, relative):
    path = root / relative
    for part in (path, *path.parents):
        if part == root:
            break
        if part.is_symlink():
            raise ValueError("Refusing symlink: " + str(relative))
    if not path.resolve().is_relative_to(root):
        raise ValueError("Path escapes project: " + str(relative))
    return path


def plan(root, name, application_id):
    if (not re.fullmatch(r"[a-z][a-z0-9]*(?:_[a-z0-9]+)*", name)
            or len(name) > 64 or name in RESERVED):
        raise ValueError("--name must be a non-reserved lower_snake_case Dart package name (max 64 chars)")
    if application_id is not None and (
        len(application_id) > 150
        or not re.fullmatch(r"[a-z][a-z0-9]*(?:\.[a-z][a-z0-9]*)+", application_id)
        or any(p in RESERVED for p in application_id.split("."))
    ):
        raise ValueError("--application-id must be a lowercase reverse-domain ID with non-reserved segments")

    def read(relative):
        return safe(root, relative).read_text(encoding="utf-8")

    manifest = read("pubspec.yaml")
    old_name = re.search(r"^name: ([a-z][a-z0-9_]*)$", manifest, re.M)
    gradle = read("android/app/build.gradle.kts")
    old_id = re.search(r'applicationId = "([a-zA-Z0-9_.]+)"', gradle)
    config = read("lib/core/config/app_config.dart")
    old_title = re.search(r"'APP_NAME',\s*defaultValue: '([^']+)'", config)
    if not old_name or not old_id or not old_title:
        raise ValueError("Expected starter package/application/title declarations were not found")
    old_name, old_id, old_title = old_name[1], old_id[1], old_title[1]
    # Omission preserves the existing application ID, also on repeated runs.
    application_id = application_id or old_id
    updates = {}

    def update(relative, content):
        path = safe(root, relative)
        if path.exists() and not path.is_file():
            raise ValueError("Expected regular file: " + str(relative))
        if not path.exists() or path.read_text(encoding="utf-8") != content:
            updates[path] = content

    update("pubspec.yaml", re.sub(r"^name: .*", "name: " + name, manifest, count=1, flags=re.M))
    for directory in ("lib", "test"):
        folder = safe(root, directory)
        for path in folder.rglob("*"):
            safe(root, path.relative_to(root))
            if path == root / "lib/firebase_options.dart":
                continue  # Private platform configuration is never opened.
            if path.suffix == ".dart" and path.is_file():
                text = path.read_text(encoding="utf-8")
                text = text.replace("package:" + old_name + "/", "package:" + name + "/")
                if path.name.startswith("app_localizations"):
                    text = text.replace("'" + old_title + "'", "'" + name + "'")
                if path == root / "lib/core/config/app_config.dart":
                    text = text.replace("defaultValue: '" + old_title + "'", "defaultValue: '" + name + "'", 1)
                # The smoke test uses the same app title as the generated resources.
                if path == root / "test/widget_test.dart":
                    text = text.replace("find.text('" + old_title + "')", "find.text('" + name + "')")
                update(path.relative_to(root), text)
    for language in ("en", "uz", "ru"):
        relative = "lib/l10n/app_" + language + ".arb"
        data = json.loads(read(relative))
        data["appTitle"] = name
        update(relative, json.dumps(data, ensure_ascii=False, indent=2) + "\n")
    for relative in ("android/app/build.gradle.kts", "ios/Runner.xcodeproj/project.pbxproj"):
        update(relative, read(relative).replace(old_id, application_id))
    for relative in ("android/app/src/main/AndroidManifest.xml", "ios/Runner/Info.plist"):
        update(relative, read(relative).replace(old_title, name))
    # Only the public example is editable; .env, signing and Firebase files are
    # deliberately absent from this allowlist and are never opened.
    relative = ".env.example"
    update(relative, re.sub(r"^APP_NAME=.*", "APP_NAME=" + name, read(relative), flags=re.M))
    source = safe(root, "android/app/src/main/kotlin/" + old_id.replace(".", "/") + "/MainActivity.kt")
    target = safe(root, "android/app/src/main/kotlin/" + application_id.replace(".", "/") + "/MainActivity.kt")
    if source != target and target.exists():
        raise ValueError("Refusing to overwrite existing MainActivity destination")
    update(target.relative_to(root), source.read_text(encoding="utf-8").replace("package " + old_id, "package " + application_id, 1))
    return updates, source if source != target else None


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--name", required=True, help="Dart package name, e.g. my_app")
    parser.add_argument("--application-id", help="Android/iOS ID, e.g. com.example.myapp; default: preserve current")
    parser.add_argument("--dry-run", action="store_true", help="Show planned paths without writing")
    args = parser.parse_args()
    root = Path(__file__).resolve().parent.parent
    try:
        updates, removed = plan(root, args.name, args.application_id)
        for path in updates:
            print(("Would update " if args.dry_run else "Update ") + str(path.relative_to(root)))
        if removed:
            print(("Would remove " if args.dry_run else "Remove ") + str(removed.relative_to(root)))
        if not args.dry_run:
            # Validate the whole plan before the first write. No subprocesses,
            # shell interpolation, dependency installs or secret generation.
            for path, text in updates.items():
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text(text, encoding="utf-8")
            if removed:
                removed.unlink()
        if not updates and not removed:
            print("Already configured; no changes")
        return 0
    except (ValueError, OSError) as error:
        print("Bootstrap refused: " + str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    sys.exit(main())
