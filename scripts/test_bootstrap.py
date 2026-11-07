"""Temporary-copy CLI tests; originals and developer secrets are never copied."""
import hashlib
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parent.parent


class BootstrapTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / "project"
        self.root.mkdir()
        for folder in ("lib", "test"):
            shutil.copytree(ROOT / folder, self.root / folder)
        files = ["scripts/bootstrap.py", "pubspec.yaml", ".env.example",
                 "android/app/build.gradle.kts", "android/app/src/main/AndroidManifest.xml",
                 "ios/Runner.xcodeproj/project.pbxproj", "ios/Runner/Info.plist"]
        files += [str(p.relative_to(ROOT)) for p in (ROOT / "android/app/src/main/kotlin").rglob("*.kt")]
        for relative in files:
            target = self.root / relative
            target.parent.mkdir(parents=True, exist_ok=True)
            shutil.copyfile(ROOT / relative, target)
        for relative in (".env", "android/key.properties", "android/app/upload-keystore.jks",
                         "ios/Runner/GoogleService-Info.plist", "lib/firebase_options.dart"):
            (self.root / relative).write_bytes(b"private fixture - never overwrite\x00")

    def snapshot(self):
        return {str(p.relative_to(self.root)): hashlib.sha256(p.read_bytes()).hexdigest()
                for p in self.root.rglob("*") if p.is_file()}

    def run_cli(self, *args, success=True):
        result = subprocess.run([sys.executable, str(self.root / "scripts/bootstrap.py"), *args],
                                cwd=self.temp.name, capture_output=True, text=True)
        self.assertEqual(result.returncode, 0 if success else 2, result.stderr)
        return result.stdout

    def test_dry_run_preserves_every_byte(self):
        before = self.snapshot()
        output = self.run_cli("--name", "sample_app", "--application-id", "org.example.sample", "--dry-run")
        self.assertIn("Would update pubspec.yaml", output)
        self.assertEqual(self.snapshot(), before)

    def test_rename_and_idempotence_preserve_secrets(self):
        before = self.snapshot()
        self.run_cli("--name", "sample_app", "--application-id", "org.example.sample")
        after = self.snapshot()
        for name in (".env", "android/key.properties", "android/app/upload-keystore.jks",
                     "ios/Runner/GoogleService-Info.plist", "lib/firebase_options.dart"):
            self.assertEqual(before[name], after[name])
        self.assertIn("name: sample_app", (self.root / "pubspec.yaml").read_text())
        self.assertTrue((self.root / "android/app/src/main/kotlin/org/example/sample/MainActivity.kt").is_file())
        self.assertIn("org.example.sample.RunnerTests", (self.root / "ios/Runner.xcodeproj/project.pbxproj").read_text())
        self.assertIn("package:sample_app/", (self.root / "lib/main.dart").read_text())
        self.assertIn("Already configured", self.run_cli("--name", "sample_app", "--application-id", "org.example.sample"))
        self.assertEqual(after, self.snapshot())
        self.run_cli("--name", "another_app")
        self.assertIn('applicationId = "org.example.sample"', (self.root / "android/app/build.gradle.kts").read_text())
        self.assertIn("package:another_app/", (self.root / "lib/main.dart").read_text())

    def test_invalid_names_and_ids_cannot_write(self):
        before = self.snapshot()
        for name in ("../outside", "Bad Name", "class", "await", "a;touch pwned", "a'", "a\nname", "a" * 65):
            self.run_cli("--name", name, success=False)
        for app_id in ("../outside", "com.class.app", "com.example.app;touch x", "com.x_", "com", "com.1app"):
            self.run_cli("--name", "sample_app", "--application-id", app_id, success=False)
        self.assertEqual(before, self.snapshot())

    def test_symlinked_target_refused_before_any_write(self):
        outside = Path(self.temp.name) / "outside"
        outside.write_text("private outside fixture")
        target = self.root / "lib/main.dart"
        target.unlink()
        target.symlink_to(outside)
        before = self.snapshot()
        self.run_cli("--name", "sample_app", success=False)
        self.assertEqual(before, self.snapshot())
        self.assertEqual(outside.read_text(), "private outside fixture")

    def test_symlinked_destination_directory_refused(self):
        outside = Path(self.temp.name) / "outside"
        outside.mkdir()
        (self.root / "android/app/src/main/kotlin/org").symlink_to(outside, target_is_directory=True)
        before = self.snapshot()
        self.run_cli("--name", "sample_app", "--application-id", "org.example.sample", success=False)
        self.assertEqual(before, self.snapshot())
        self.assertEqual(list(outside.iterdir()), [])

    def test_existing_destination_refused_before_any_write(self):
        destination = self.root / "android/app/src/main/kotlin/org/example/sample/MainActivity.kt"
        destination.parent.mkdir(parents=True)
        destination.write_text("do not overwrite")
        before = self.snapshot()
        self.run_cli("--name", "sample_app", "--application-id", "org.example.sample", success=False)
        self.assertEqual(before, self.snapshot())


if __name__ == "__main__":
    unittest.main()
