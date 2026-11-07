import 'dart:async';

import 'package:flutter_boilerplate/core/storage/coalesced_read.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'shares only overlapping reads, including null; never caches a value',
    () async {
      var calls = 0;
      String? persisted;
      final gate = Completer<void>();
      final value = CoalescedRead(() async {
        calls++;
        await gate.future;
        return persisted;
      });
      final first = value.read();
      final second = value.read();
      gate.complete();
      expect(await Future.wait([first, second]), [null, null]);
      expect(calls, 1);
      persisted = 'external update';
      expect(await value.read(), 'external update');
      expect(calls, 2);
    },
  );

  test('login, refresh and logout invalidate already-started reads', () async {
    for (final replacement in <String?>['login', 'rotated', null]) {
      String? persisted = 'old';
      final started = Completer<void>();
      final release = Completer<void>();
      var first = true;
      final value = CoalescedRead(() async {
        final snapshot = persisted;
        if (first) {
          first = false;
          started.complete();
          await release.future;
        }
        return snapshot;
      });
      final stale = value.read();
      await started.future;
      await value.write(() async => persisted = replacement);
      release.complete();
      expect(await stale, replacement);
      expect(await value.read(), replacement);
    }
  });

  test('reads wait for ordered writes and newest locale selection', () async {
    var persisted = 'en';
    final gate = Completer<void>();
    final value = CoalescedRead(() async => persisted);
    final first = value.write(() async {
      await gate.future;
      persisted = 'uz';
    });
    final second = value.write(() async => persisted = 'ru');
    final reading = value.read();
    gate.complete();
    await Future.wait([first, second]);
    expect(await reading, 'ru');
  });

  test(
    'failed reads and writes are not cached or allowed to poison later work',
    () async {
      var fail = true;
      var persisted = 'old';
      final value = CoalescedRead(() async {
        if (fail) throw StateError('synthetic read error');
        return persisted;
      });
      await expectLater(value.read(), throwsStateError);
      fail = false;
      expect(await value.read(), 'old');
      await expectLater(
        value.write(() async => throw StateError('synthetic write error')),
        throwsStateError,
      );
      expect(await value.read(), 'old');
      await value.write(() async => persisted = 'new');
      expect(await value.read(), 'new');
    },
  );
}
