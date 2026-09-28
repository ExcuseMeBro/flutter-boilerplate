## Purpose

Keep Firebase optional without delaying the first application frame, while ensuring notification authorization happens only after a clear user action.

## ADDED Requirements

### Requirement: Firebase initialization does not block application startup
The application SHALL render its core UI without waiting for Firebase initialization to finish.

#### Scenario: Firebase initialization is pending
- **WHEN** application startup begins and Firebase initialization has not completed
- **THEN** the core UI SHALL render and SHALL expose a loading Firebase status without blocking startup

#### Scenario: Firebase configuration is absent
- **WHEN** Firebase initialization fails because configuration is absent
- **THEN** the application SHALL remain usable and SHALL display an unconfigured Firebase status

### Requirement: Notification permission is user-triggered
The application SHALL NOT request notification authorization during startup and SHALL request it only after the user activates the notification action in Settings.

#### Scenario: Application starts
- **WHEN** the application starts
- **THEN** no notification permission prompt SHALL be requested automatically

#### Scenario: User enables notifications
- **WHEN** Firebase is configured and the user activates the notification action
- **THEN** the application SHALL request platform notification permission and report the resulting authorization state without crashing

### Requirement: Configured notification handling remains available
After Firebase and local notifications initialize successfully, foreground Firebase notifications and FCM token retrieval SHALL remain available.

#### Scenario: Foreground notification arrives
- **WHEN** a configured application receives a foreground message containing notification content
- **THEN** a local notification SHALL be displayed

#### Scenario: User requests the FCM token
- **WHEN** Firebase is configured and the user requests the token from Settings
- **THEN** the application SHALL report the token or a localized unavailable message
