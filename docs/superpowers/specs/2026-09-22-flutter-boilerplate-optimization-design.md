# Flutter Boilerplate Optimization Design

## Approved direction

Use the balanced production approach: retain Riverpod, GoRouter, Dio, secure storage, Firebase, local notifications, and `intl`; remove unused direct packages; implement generated en/uz/ru localization with a persisted user choice that defaults to the system locale; make Firebase non-blocking; request notification permission only from Settings; validate release API configuration; and pin/build-test the supported Flutter toolchain in CI.

Do not add Freezed, Retrofit, GetIt, Talker, a database, authentication screens, flavors, or other speculative infrastructure.

## Canonical artifacts

The detailed, validated design and behavior contracts live in:

- `../../../openspec/changes/optimize-flutter-boilerplate/proposal.md`
- `../../../openspec/changes/optimize-flutter-boilerplate/design.md`
- `../../../openspec/changes/optimize-flutter-boilerplate/specs/`
- `../../../openspec/changes/optimize-flutter-boilerplate/tasks.md`

Implementation must preserve the dirty primary checkout, copy its current WIP read-only into the isolated task worktree, follow test-first behavior changes, and deliver only after the prerequisite history rewrite is resolved.
