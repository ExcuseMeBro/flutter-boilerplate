# Architecture

This template keeps only reusable production foundations from BabyTime mobile app.

## Rules

- Feature-first folders under `lib/features`.
- Shared infrastructure under `lib/core`.
- No generated code by default.
- No app-specific screens, assets, endpoints, or secrets.
- All environment-specific values come from `--dart-define`.

## Networking

`ApiClient` wraps Dio and exposes typed request helpers. `AuthInterceptor` adds bearer token, language header, and one-shot token refresh for `401` responses.

Refresh endpoint default: `/auth/refresh/` under configured API base.

## Storage

- Access/refresh tokens are saved in secure storage.
- SharedPreferences mirrors auth values only for app convenience.
- `clearAuth()` clears both stores.

## Firebase

`FirebaseBootstrap.initialize()` catches missing Firebase config, so fresh templates compile and run before `flutterfire configure`.
