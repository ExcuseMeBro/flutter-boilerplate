# Request storage profile

## Method

Run the committed harness in isolation:

```bash
flutter test test/core/network/request_storage_profile_test.dart --no-pub --reporter expanded
```

It exercises the real Dio `AuthInterceptor`, `SecureStorage` wrapper and
`LocalStorage`. Only platform storage and HTTP transport are replaced: each
platform read has a synthetic 1 ms delay, and the in-memory HTTP adapter returns
200 without network access. Each configuration has 7 samples of 100 requests,
concurrency 1, 10 or 100, after one warm-up request and startup migration.
It emits elapsed microseconds and storage call counts only, never credentials.

Measured locally on macOS arm64, Flutter 3.47.9 / Dart 3.13.7, same harness and
machine before/after. Baseline storage implementation is commit
`64735c040d203dd1a822f60805343ce13c10d8fd`. To reproduce the baseline, copy this test
into a disposable checkout of that commit, resolve its locked dependencies, and
run the command above. Do not replace files in a working development checkout.

## Results

Each read-count pair is (secure access-token reads, async locale reads) per
100 requests; counts were identical in all 7 samples.

| Concurrency | Baseline reads | Final reads | Baseline median (µs) | Final median (µs) | Baseline min–max (µs) | Final min–max (µs) |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | 100, 100 | 100, 100 | 538588 | 531631 | 527874–573245 | 516184–556078 |
| 10 | 100, 100 | 10, 10 | 99454 | 68857 | 72210–198341 | 66166–71342 |
| 100 | 100, 100 | 1, 1 | 31788 | 22721 | 26696–46449 | 21211–24665 |

The repeatable benefit is a 90%/99% reduction in overlapping platform reads at
concurrency 10/100. Synthetic median elapsed time fell about 31%/29%; sequential
performance is effectively unchanged. Timing is scheduler/JIT-sensitive and is
not a measured device Keychain/Keystore latency or production network benchmark.
No real-device speedup claim is made; validate on target hardware for that claim.

## Chosen change and safety

Use **in-flight coalescing**, not a session-lifetime value cache: overlapping reads
share one pending platform call; completed values are immediately released. This
keeps tokens in secure storage, observes external changes on the next
non-overlapping read and avoids holding credentials longer than necessary.

Per-key writes are serialized. Login, refresh, logout and locale writes advance
a generation and invalidate pending reads. An old read resolves against the
current generation, not its old snapshot. Read/write errors remain observable;
a failed write cannot permanently poison the queue. All app writes must go
through these wrappers; external writers cannot invalidate an already-started
platform read (but no completed value is cached).

Tests cover overlapping reads, null values, external updates, pending reads across
login/refresh/logout, ordered locale writes, failed read/write recovery, secure
persistence and clearing both token keys. Existing auth-interceptor regressions
retain concurrent-401 single-flight refresh, rotated-token replay, one retry,
failed-refresh cleanup and locale headers. No interceptor retry policy was changed.
