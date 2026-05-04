# Testing Guide

## Philosophy

MyPepTracker uses **Swift Testing** for unit tests and **XCTest** for UI tests. Swift Testing is modern, supports parameterized tests and `#require`, and is the preferred framework for new tests. XCTest is retained for UI tests because Swift Testing has limited UI test support.

## Running Tests

```bash
# Generate project (required after project.yml changes)
xcodegen generate

# Run unit tests
xcodebuild -project MyPepTracker.xcodeproj -scheme MyPepTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test

# Run SwiftLint
swiftlint

# Run all checks (what CI does)
xcodegen generate && \
  xcodebuild -project MyPepTracker.xcodeproj -scheme MyPepTracker \
    -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build test && \
  swiftlint
```

## Test Organization

All test files live in `MyPepTrackerTests/` (unit) and `MyPepTrackerUITests/` (UI).

### @Suite Tags

Group related tests with tags for selective runs:

```swift
@Suite("Models", .tags(.model))
struct PeptideTests { ... }

@Suite("Services", .tags(.service))
struct ConcentrationCalculatorTests { ... }
```

Run only model tests: `swift test --filter .model` (when CLI test runner is available).

### Shared Infrastructure

`TestHelpers.swift` provides:

```swift
/// In-memory SwiftData context for isolated tests.
func makeInMemoryContext() throws -> ModelContext

/// Fixed-date provider for deterministic assertions.
struct FixedDateProvider: DateProvider
func setFixedDate(_ date: Date)

/// Reset to live clock after each test.
DateProviderRegistry.reset()
```

Always reset the date provider in tear-down:

```swift
@Test func cycleProgressAtStart() {
    setFixedDate(myFixedDate)
    defer { DateProviderRegistry.reset() }
    // ... assertions
}
```

## Writing Model Tests

```swift
@MainActor
struct PeptideTests {
    @Test func activeVialReturnsFirstNonExpired() {
        let peptide = Peptide(name: "BPC-157", defaultDoseMcg: 250,
                              scheduleType: .fixedRecurring, frequency: .daily)
        let fresh = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0, isActive: true)
        let expired = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0,
                           dateMixed: Calendar.current.date(byAdding: .day, value: -40, to: Date())!,
                           isActive: true)
        peptide.vials = [expired, fresh]
        #expect(peptide.activeVial === fresh)
    }
}
```

### Key Patterns

- Use `@MainActor` for any test touching SwiftData (`@Model` types)
- Use `#require` for preconditions (fails fast with clear message)
- Use `#expect` for assertions
- Use `makeInMemoryContext()` instead of copy-pasting container setup

## Writing Service Tests

Pure services (no SwiftData) don't need `@MainActor`:

```swift
@Suite("ConcentrationCalculator")
struct ConcentrationCalculatorTests {
    @Test(arguments: [
        (5.0, 2.0, 2500.0),
        (10.0, 1.0, 10000.0),
    ])
    func concentration(peptideMg: Double, waterML: Double, expected: Double) {
        let result = ConcentrationCalculator.concentrationMcgPerML(
            peptideAmountMg: peptideMg, waterVolumeML: waterML
        )
        #expect(result == expected)
    }
}
```

### Date-Dependent Tests

```swift
@Test func isExpiredWhenPastExpiry() {
    let fixedNow = Calendar.current.date(from: DateComponents(year: 2024, month: 1, day: 15))!
    setFixedDate(fixedNow)
    defer { DateProviderRegistry.reset() }

    let mixed = Calendar.current.date(byAdding: .day, value: -31, to: fixedNow)!
    let vial = Vial(peptideAmountMg: 5.0, waterVolumeML: 2.0,
                    dateMixed: mixed, expiryDays: 30)
    #expect(vial.isExpired == true)
}
```

## Writing UI Tests

UI tests use XCTest. Prefer `waitForExistence` over fixed sleeps:

```swift
// ✅ Good — explicit, fast
let button = app.buttons["Log Dose"]
XCTAssertTrue(button.waitForExistence(timeout: 3))
button.tap()

// ❌ Bad — slow, flaky
pause(0.5)
button.tap()
```

### Screenshot Tests

Screenshot tests run in `-screenshotMode` with seeded data:

```bash
# Run screenshot tests and extract images
xcodebuild test -scheme MyPepTracker \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing MyPepTrackerUITests/ScreenshotTests

# Extract from xcresult
xcrun xcresulttool get path-to.xcresult --format json
```

## Coverage Gaps (intentional)

| Untested | Why | Risk |
|----------|-----|------|
| `NotificationManager` actual scheduling | Requires `UNUserNotificationCenter` singleton | Low — `nextDoseDate()` logic is fully tested |
| `HealthKitService` | Requires HealthKit entitlement + device | Low — thin wrapper around HKHealthStore |
| `WidgetSyncService` | Requires App Group + WidgetKit | Low — thin UserDefaults write |
| SwiftUI views | Complex to test; smoke tests catch crashes | Medium — consider ViewInspector for critical sheets |

## CI

Tests run on every push via `.forgejo/workflows/test.yml`:

1. `xcodegen generate`
2. `xcodebuild build`
3. `xcodebuild test`
4. `swiftlint`
