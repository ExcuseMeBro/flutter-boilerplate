import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_boilerplate/core/config/app_config.dart';
import 'package:flutter_boilerplate/app/app.dart';
import 'package:flutter_boilerplate/core/firebase/firebase_bootstrap.dart';
import 'package:flutter_boilerplate/core/firebase/push_notification_service.dart';
import 'package:flutter_boilerplate/core/storage/secure_storage.dart';
import 'package:flutter_boilerplate/features/game/game_engine.dart';
import 'package:flutter_boilerplate/features/home/home_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/in_memory_preferences.dart';
import 'support/notification_settings.dart';

void main() {
  late SharedPreferencesAsync prefs;

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    prefs = installInMemoryPreferences();
  });

  Widget app({
    FirebaseStatus? status,
    Completer<FirebaseStatus>? pending,
    Future<bool> Function(Uri)? externalLinkOpener,
  }) {
    return ProviderScope(
      overrides: [
        secureStorageProvider.overrideWithValue(const SecureStorage()),
        if (externalLinkOpener != null)
          externalLinkOpenerProvider.overrideWithValue(externalLinkOpener),
        if (pending != null)
          firebaseStatusProvider.overrideWith((ref) => pending.future)
        else
          firebaseStatusProvider.overrideWith(
            (ref) async => status ?? const FirebaseStatus.unconfigured(),
          ),
      ],
      child: const Game2048App(),
    );
  }

  testWidgets('renders the 2048 board in English', (tester) async {
    await tester.pumpWidget(app(status: const FirebaseStatus.unconfigured()));
    await tester.pumpAndSettle();

    expect(find.text('2048'), findsNWidgets(2));
    expect(find.text('Small moves. Big wins.'), findsOneWidget);
    expect(find.text('Merge matching tiles.'), findsOneWidget);
    expect(find.text('Score'), findsOneWidget);
    expect(find.text('Best'), findsOneWidget);
    expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    expect(find.text('2048'), findsNWidgets(2));
  });

  testWidgets('switches to Uzbek in Settings and persists the selection',
      (tester) async {
    await tester.pumpWidget(app(status: const FirebaseStatus.unconfigured()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Settings'), findsWidgets);

    await tester.tap(find.byType(DropdownButtonFormField<Locale>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Uzbek').last);
    await tester.pumpAndSettle();

    expect(find.text('Sozlamalar'), findsWidgets);
    expect(find.text('Til'), findsOneWidget);
    expect(await prefs.getString('${AppConfig.appName}.locale'), 'uz');
  });

  testWidgets('renders the game while Firebase initialization is pending',
      (tester) async {
    final pending = Completer<FirebaseStatus>();
    var permissionRequests = 0;
    PushNotificationService.permissionRequester = () async {
      permissionRequests++;
      return notificationSettings(AuthorizationStatus.authorized);
    };
    addTearDown(PushNotificationService.resetTestSeams);

    await tester.pumpWidget(app(pending: pending));
    await tester.pump();

    expect(find.text('2048'), findsNWidgets(2));
    expect(permissionRequests, 0,
        reason: 'startup must not prompt for notification permission');

    pending.complete(const FirebaseStatus.unconfigured());
    await tester.pumpAndSettle();
  });

  testWidgets('requests notification permission only from the Settings action',
      (tester) async {
    var permissionRequests = 0;
    PushNotificationService.permissionRequester = () async {
      permissionRequests++;
      return notificationSettings(AuthorizationStatus.authorized);
    };
    addTearDown(PushNotificationService.resetTestSeams);

    await tester.pumpWidget(app(status: const FirebaseStatus.configured()));
    await tester.pumpAndSettle();

    expect(permissionRequests, 0);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable notifications'));
    await tester.pumpAndSettle();

    expect(permissionRequests, 1);
    expect(find.text('Notifications enabled.'), findsOneWidget);
  });

  testWidgets('reports a denied notification permission without crashing',
      (tester) async {
    PushNotificationService.permissionRequester = () async =>
        notificationSettings(AuthorizationStatus.denied);
    addTearDown(PushNotificationService.resetTestSeams);

    await tester.pumpWidget(app(status: const FirebaseStatus.configured()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable notifications'));
    await tester.pumpAndSettle();

    expect(find.text('Notification permission was denied.'), findsOneWidget);
  });

  testWidgets('survives a notification permission exception', (tester) async {
    PushNotificationService.permissionRequester =
        () async => throw Exception('permission failed');
    addTearDown(PushNotificationService.resetTestSeams);

    await tester.pumpWidget(app(status: const FirebaseStatus.configured()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enable notifications'));
    await tester.pumpAndSettle();

    expect(
      find.text('Notification permission is unavailable on this device.'),
      findsOneWidget,
    );
  });

  testWidgets('survives an FCM token exception', (tester) async {
    PushNotificationService.tokenProvider =
        () async => throw Exception('token failed');
    addTearDown(PushNotificationService.resetTestSeams);

    await tester.pumpWidget(app(status: const FirebaseStatus.configured()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check FCM token'));
    await tester.pumpAndSettle();

    expect(find.text('FCM token unavailable.'), findsOneWidget);
  });

  testWidgets('copies a retrieved FCM token to the clipboard', (tester) async {
    PushNotificationService.tokenProvider = () async => 'token-abc';
    addTearDown(PushNotificationService.resetTestSeams);

    final clipboardWrites = <String>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          clipboardWrites.add((call.arguments as Map)['text'] as String);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(app(status: const FirebaseStatus.configured()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check FCM token'));
    await tester.pumpAndSettle();

    expect(find.text('FCM token copied to clipboard.'), findsOneWidget);
    expect(clipboardWrites, ['token-abc']);
  });

  testWidgets('survives a clipboard write failure', (tester) async {
    PushNotificationService.tokenProvider = () async => 'token-abc';
    addTearDown(PushNotificationService.resetTestSeams);

    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          throw PlatformException(code: 'clipboard_failure');
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(app(status: const FirebaseStatus.configured()));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Check FCM token'));
    await tester.pumpAndSettle();

    expect(find.text('FCM token unavailable.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('swipe moves tiles, saves the board and opens a new game', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final initial = GameSession(
      current: GameSnapshot([
        0,
        0,
        0,
        0,
        2,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
        0,
      ], 0),
      best: 0,
    );
    final store = installInMemoryPreferences({
      'game2048.session.v1': initial.encode(),
    });
    Uri? openedUri;
    await tester.pumpWidget(
      app(
        externalLinkOpener: (uri) async {
          openedUri = uri;
          return true;
        },
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byType(AspectRatio));
    await tester.drag(find.byType(AspectRatio), const Offset(100, 0));
    await tester.pumpAndSettle();
    final saved = GameSession.restore(
      await store.getString('game2048.session.v1'),
    )!;
    expect(saved.previous!.board, initial.current.board);
    expect(saved.current.board[7], 2);

    await tester.scrollUntilVisible(find.text('New game'), 120);
    await tester.tap(find.text('New game'));
    await tester.pumpAndSettle();
    expect(find.text('Start a new game?'), findsOneWidget);
    expect(
      find.text(
        'Your current game will be lost. Your best score will be saved.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(
      GameSession.restore(
        await store.getString('game2048.session.v1'),
      )!.current.board,
      saved.current.board,
    );

    await tester.scrollUntilVisible(find.text('Developed by Bro'), 120);
    await tester.tap(find.text('Developed by Bro'));
    await tester.pumpAndSettle();
    expect(openedUri, Uri.parse('https://brodev.uz'));
  });

  testWidgets('shows a helpful message when the developer link cannot open', (
    tester,
  ) async {
    await tester.pumpWidget(
      app(externalLinkOpener: (uri) async => false),
    );
    await tester.pumpAndSettle();
    expect(find.text('2048'), findsNWidgets(2));
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Developed by Bro'));
    await tester.pump();
    expect(
      find.text("Couldn't open brodev.uz. Try opening it in your browser."),
      findsOneWidget,
    );
  });
}
