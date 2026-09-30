# Upgrade Plan — Cron Mobile

## Current state

Score: 7.5/10 — core feature with edge-case-tested pure-Dart logic, a11y guideline tests, honest CI and fail-closed signing; no app icon or E2E flow yet.

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
- Localisation (Thai/English) for UI strings.

## Done in this pass (pass 3)

- Bug fix: numbers were parsed with `int.tryParse`, so `0x1F` and `+5` were accepted as 31 and 5; fields now accept plain decimal digits only.
- Bug fix: day-of-month/day-of-week OR rule now follows crontab(5) — a field starting with `*` (e.g. `*/2`) counts as unrestricted, so `0 0 */2 * MON` means "odd days that are Mondays", not "odd days or Mondays". Description joins with "and"/"or" accordingly.
- Bug fix: `*/1` described as "Every 1 minutes"/"every 1 hours"; now "Every minute"/"every hour".
- Edge-case unit tests: hex/sign input, unknown macros, malformed lists/ranges, Sunday-as-7 in ranges, month/year/leap rollover, `count: 0`, empty `compressRanges`. (DST spring-forward was probed under `TZ=America/New_York`: no loop.)
- Accessibility: description is a live region; example chips have tooltips; widget tests assert `androidTapTargetGuideline`, `labeledTapTargetGuideline`, `textContrastGuideline` and a 200% text-scale layout.
- Widget tests for example chips, empty-input error and the "never fires" state.
- The 200% text-scale widget test now runs at a 360 px phone width (it previously used the 800 px default test surface); no overflow found.

## Done in pass 2

- Release builds no longer sign with the debug key: `android/app/build.gradle.kts` reads the ignored `android/key.properties` and a Gradle guard fails any release assemble/bundle without it (pattern from `bookchaowalit-goal-tracker-mobile`). Root `.gitignore` also ignores `key.properties`, `*.jks`, `*.keystore`; README documents the setup. Not build-verified here (no Android SDK/Gradle in this environment).


## Done in pass 1

- Replaced the Expo/npm CI (which could never fail) with fail-closed Flutter CI: `dart format` check, `flutter analyze`, `flutter test`, debug APK on `main`.
- Implemented the core feature (parse a five-field cron expression, read it in plain english and preview upcoming runs) with pure-Dart logic in `lib/logic/`.
- Replaced placeholder Explore/Profile tabs with an About screen describing features and privacy.
- Added unit tests for the logic and widget tests for the main journey.
- Removed unused `go_router` / `flutter_riverpod` dependencies; README now matches the code.
