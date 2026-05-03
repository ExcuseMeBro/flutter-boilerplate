import 'package:flutter/material.dart';
import 'package:flutter_boilerplate/app/app.dart';
import 'package:flutter_boilerplate/core/firebase/firebase_bootstrap.dart';
import 'package:flutter_boilerplate/core/storage/local_storage.dart';
import 'package:flutter_boilerplate/core/storage/secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders home page', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          secureStorageProvider.overrideWithValue(const SecureStorage()),
          firebaseStatusProvider.overrideWithValue(
            const FirebaseStatus.unconfigured(),
          ),
        ],
        child: const BoilerplateApp(),
      ),
    );

    expect(find.text('Production Flutter starter'), findsOneWidget);
    expect(find.byIcon(Icons.rocket_launch_outlined), findsOneWidget);
  });
}
