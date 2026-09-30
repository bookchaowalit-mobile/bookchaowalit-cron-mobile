# Cron — Mobile

Parse a five-field cron expression, read it in plain English and preview upcoming runs.

Part of [Chaowalit Greepoke](https://bookchaowalit.com)'s 101 Portfolio Projects.

## Features

- Parses minute, hour, day-of-month, month and day-of-week fields (lists, ranges, steps, names)
- Plain-English description of the schedule
- Previews the next five run times from now
- Clear error messages for invalid expressions

Data lives in memory for the current session only; there is no account,
backend, analytics or network access.

## Tech Stack

- **Framework:** Flutter (CI pinned to 3.47.5) + Material 3
- **Language:** Dart
- **State:** `StatefulWidget` / `setState`; the core logic is pure Dart in
  `lib/logic/` and unit-tested without widgets

## Develop and verify

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter run
```

CI (`.github/workflows/build.yml`) runs the same format/analyze/test checks
and fails closed; a debug APK is built on pushes to `main`.

## Build

```bash
# Android
flutter build apk --debug
```

Release signing is not configured yet (see `docs/UPGRADE-PLAN.md`).

## Related

- **Frontend:** [bookchaowalit-website/cron-frontend](https://github.com/bookchaowalit-website/cron-frontend)
- **Portfolio:** [bookchaowalit.com](https://bookchaowalit.com)

## License

MIT
