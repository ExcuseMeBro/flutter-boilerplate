## Purpose

Prevent distributable builds from silently targeting the boilerplate placeholder backend while preserving the zero-configuration development experience.

## ADDED Requirements

### Requirement: Release API configuration is validated before launch
A release-mode application SHALL refuse to launch when `API_BASE_URL` is missing, malformed, non-HTTPS, or still points to the documented placeholder host.

#### Scenario: Placeholder endpoint in release mode
- **WHEN** a release build starts with `https://api.example.com`
- **THEN** startup SHALL fail with a clear configuration error before rendering the application

#### Scenario: Invalid endpoint in release mode
- **WHEN** a release build starts with a malformed or non-HTTPS API base URL
- **THEN** startup SHALL fail with a clear configuration error

#### Scenario: Valid production endpoint
- **WHEN** a release build starts with an absolute HTTPS API base URL that is not the placeholder
- **THEN** configuration validation SHALL allow application startup to continue

### Requirement: Development remains runnable with defaults
Debug and test execution SHALL continue to permit the placeholder API endpoint so a newly cloned template can run before backend configuration.

#### Scenario: Debug startup with defaults
- **WHEN** a debug build starts without API dart-defines
- **THEN** configuration validation SHALL not block application startup
