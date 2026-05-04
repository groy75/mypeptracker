# MyPepTracker

Personal peptide dose, vial, and body measurement tracker for iOS.

[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![iOS 17+](https://img.shields.io/badge/iOS-17.0+-blue.svg)](https://developer.apple.com/ios)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Features

- **Peptide tracking** — Log doses with mcg/mL/IU conversion, injection sites, and notes
- **Vial management** — Reconstitution calculator, expiry warnings, low-dose alerts
- **Smart scheduling** — Fixed recurring (with weekday support) or interval-based dosing
- **Body metrics** — Weight, body fat, measurements with goals and Swift Charts history
- **Notifications** — Dose reminders, overdue alerts, vial expiry warnings
- **Privacy-first** — All data stays on device; optional iCloud sync via SwiftData + CloudKit
- **Apple Health** — Sync weight and body fat % to HealthKit
- **Import/Export** — JSON and CSV for backup and migration
- **Home Screen Widget** — Next dose countdown and active vial count

## Tech Stack

- Swift 6 + SwiftUI + SwiftData
- iOS 17.0 minimum
- Xcode 16+ (xcodegen-driven project)
- Swift Testing for unit tests
- XCTest for UI tests

## Build

```bash
# Generate Xcode project from project.yml
xcodegen generate

# Build
xcodebuild -project MyPepTracker.xcodeproj -scheme MyPepTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build

# Test
xcodebuild -project MyPepTracker.xcodeproj -scheme MyPepTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test
```

## Project Structure

```
MyPepTracker/
├── MyPepTrackerApp.swift          # Entry point, ModelContainer, CloudKit
├── ContentView.swift              # TabView root
├── Models/                        # SwiftData @Model types
├── Services/                      # Business logic (testable, pure)
├── Views/                         # SwiftUI views by tab
│   ├── Today/
│   ├── Peptides/
│   ├── History/
│   ├── Body/
│   └── Settings/
├── Theme/                         # Colors, spacing
└── Resources/                     # Assets, peptide-presets.json

MyPepTrackerTests/                 # Unit tests (Swift Testing)
MyPepTrackerUITests/               # UI tests (XCTest)
MyPepTrackerWidget/                # Home Screen widget extension
```

## Architecture

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for data model diagrams, service responsibilities, and design decisions.

See [`docs/TESTING.md`](docs/TESTING.md) for testing philosophy, patterns, and CI setup.

## Release Process

1. Update `project.yml`: bump `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`
2. Run `xcodegen generate`
3. Archive and upload to App Store Connect
4. Append row to `RELEASES.md`
5. Tag: `git tag v<marketing>-b<build> && git push --tags`

See [`RELEASES.md`](RELEASES.md) for full history.

## License

MIT © Greg Roy
