# Upgrade Plan — Cron Mobile

## Current state

Score: 7/10 — core feature with tested pure-Dart logic, honest CI and fail-closed release signing; still no app icon or E2E flow.

## Backlog

### P0
- None open. (Release signing now fails closed without `android/key.properties`.)

### P1
- Remember recent expressions (shared_preferences) and offer common presets.
- Timezone selection for the next-run preview.
- Replace the template launcher icon with a real app icon (the application ID `com.bookchaowalit.*` is already set).
- Add a Maestro smoke flow for the main journey.
- Add a CI job that builds a signed release bundle from repository secrets (keystore decoded at runtime, never committed).

### P2
- Tablet layout (NavigationRail) and 130% text-scale widget test.
- Localisation (Thai/English) for UI strings.

## Done in this pass (pass 2)

- Release builds no longer sign with the debug key: `android/app/build.gradle.kts` reads the ignored `android/key.properties` and a Gradle guard fails any release assemble/bundle without it (pattern from `bookchaowalit-goal-tracker-mobile`). Root `.gitignore` also ignores `key.properties`, `*.jks`, `*.keystore`; README documents the setup. Not build-verified here (no Android SDK/Gradle in this environment).


## Done in pass 1

- Replaced the Expo/npm CI (which could never fail) with fail-closed Flutter CI: `dart format` check, `flutter analyze`, `flutter test`, debug APK on `main`.
- Implemented the core feature (parse a five-field cron expression, read it in plain english and preview upcoming runs) with pure-Dart logic in `lib/logic/`.
- Replaced placeholder Explore/Profile tabs with an About screen describing features and privacy.
- Added unit tests for the logic and widget tests for the main journey.
- Removed unused `go_router` / `flutter_riverpod` dependencies; README now matches the code.
