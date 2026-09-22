## Purpose

Provide one consistent en/uz/ru locale across visible application text and API requests, using the device locale initially and preserving an explicit user choice across launches.

## ADDED Requirements

### Requirement: Generated supported localizations
The application SHALL provide generated English, Uzbek, and Russian localizations for every user-visible string in the starter screens.

#### Scenario: Supported locale renders translated text
- **WHEN** the active locale is English, Uzbek, or Russian
- **THEN** Home and Settings SHALL render strings from the corresponding generated localization resources

### Requirement: System locale is the initial default
When no valid locale preference exists, the application SHALL select the device locale when it is supported and SHALL fall back to English otherwise.

#### Scenario: Supported system locale
- **WHEN** the device locale is Uzbek and no preference is saved
- **THEN** the application SHALL start in Uzbek

#### Scenario: Unsupported system locale
- **WHEN** the device locale is not English, Uzbek, or Russian and no preference is saved
- **THEN** the application SHALL start in English

### Requirement: Explicit locale selection persists
The Settings screen SHALL let the user select English, Uzbek, or Russian, apply the selection immediately, and restore it on subsequent launches.

#### Scenario: User changes locale
- **WHEN** the user selects Russian in Settings
- **THEN** visible application text SHALL switch to Russian and the selection SHALL be persisted

#### Scenario: Saved locale overrides system locale
- **WHEN** Russian is saved and the device locale is Uzbek
- **THEN** the application SHALL start in Russian

### Requirement: API locale matches the application
Authenticated and unauthenticated API requests SHALL send the active application language code in the `Accept-Language` header.

#### Scenario: Request after locale change
- **WHEN** the user changes the active locale to Uzbek and an API request is sent
- **THEN** the request SHALL contain `Accept-Language: uz`
