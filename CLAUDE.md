# MyPepTracker — notes for Claude

## Release / App Store submission

**Before archiving for App Store or TestFlight, read `RELEASES.md` first.** It's the
source of truth for version and build number. The `CURRENT_PROJECT_VERSION` in
`project.yml` must be strictly higher than every build ever uploaded to App Store
Connect — `RELEASES.md` tracks that number.

Versions live in `project.yml` (xcodegen regenerates the Xcode project from it):
- `MARKETING_VERSION` — user-visible version, bump for each feature/marketing release.
- `CURRENT_PROJECT_VERSION` — build number, bump for **every** upload attempt.

After a successful upload, append a row to the history table in `RELEASES.md`
and tag the commit: `git tag v<marketing>-b<build> && git push --tags`.

## Project shape

- SwiftUI + SwiftData, iOS 17.0 minimum, Swift 6.
- Models: `Peptide → Vial → DoseEntry` (cascade delete from Peptide).
- Views organized by tab: `Today`, `Peptides`, `History`, `Settings`.
- Tests use the `Testing` framework (not XCTest), see `MyPepTrackerTests/`.
- Project is xcodegen-driven — edit `project.yml`, then `xcodegen generate`.
  Never hand-edit `MyPepTracker.xcodeproj/project.pbxproj`.

## Build commands

```sh
xcodegen generate
xcodebuild -project MyPepTracker.xcodeproj -scheme MyPepTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build

xcodebuild -project MyPepTracker.xcodeproj -scheme MyPepTracker \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' test
```
