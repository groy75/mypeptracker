# MyPepTracker Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build MyPepTracker, a personal iOS app for tracking peptide reconstitution, dosing, and push notification reminders.

**Architecture:** SwiftUI app with SwiftData persistence, local-only storage. Four-tab navigation (Today, Peptides, History, Settings). UNUserNotificationCenter for all reminders. Bundled JSON preset library for common peptides. No backend, no accounts.

**Tech Stack:** Swift 6.3, SwiftUI, SwiftData, UNUserNotificationCenter, Xcode 26.4, iOS 17+

---

## File Structure

```
MyPepTracker/
├── MyPepTrackerApp.swift                    # App entry point, ModelContainer setup
├── ContentView.swift                        # TabView root
├── Models/
│   ├── Peptide.swift                        # @Model: peptide entity
│   ├── Vial.swift                           # @Model: vial entity
│   ├── DoseEntry.swift                      # @Model: dose log entry
│   ├── ScheduleType.swift                   # Enum: fixedRecurring / afterDose
│   ├── InjectionSite.swift                  # Enum: body sites
│   └── PeptidePreset.swift                  # Codable struct for bundled presets
├── Services/
│   ├── NotificationManager.swift            # Schedule/cancel local notifications
│   └── ConcentrationCalculator.swift        # Dose math utilities
├── Views/
│   ├── Today/
│   │   ├── TodayView.swift                  # Tab 1: daily dashboard
│   │   ├── PeptideCardView.swift            # Card for each active peptide
│   │   └── LogDoseSheet.swift               # Half-sheet for logging a dose
│   ├── Peptides/
│   │   ├── PeptideListView.swift            # Tab 2: peptide roster
│   │   ├── PeptideDetailView.swift          # Detail: schedule, vials, history
│   │   ├── AddPeptideView.swift             # Add from preset or custom
│   │   └── ReconstitutionSheet.swift        # New vial form
│   ├── History/
│   │   ├── HistoryView.swift                # Tab 3: dose log timeline
│   │   ├── DoseEntryRow.swift               # Single dose entry in list
│   │   └── BodyMapView.swift                # Injection site visualization
│   └── Settings/
│       └── SettingsView.swift               # Tab 4: preferences, export
├── Resources/
│   └── peptide-presets.json                 # Bundled preset catalog
└── Theme/
    └── AppTheme.swift                       # Colors, spacing, radius constants

MyPepTrackerTests/
├── ConcentrationCalculatorTests.swift       # Unit tests for dose math
├── VialTests.swift                          # Derived property tests
├── NotificationManagerTests.swift           # Scheduling logic tests
└── PeptidePresetTests.swift                 # Preset loading tests
```

---

### Task 1: Xcode Project Scaffolding

**Files:**
- Create: Xcode project `MyPepTracker` at `~/repos/peptide-tracker/`
- Create: `MyPepTracker/Theme/AppTheme.swift`

- [ ] **Step 1: Create the Xcode project**

```bash
cd ~/repos/peptide-tracker
# Create project using Xcode command line
# Open Xcode to create: File > New > Project > App
# Product Name: MyPepTracker
# Organization Identifier: com.greg.roy
# Interface: SwiftUI
# Storage: SwiftData
# Include Tests: Yes
# Location: ~/repos/peptide-tracker/
```

Since this is a greenfield project, create it via Xcode's project template with SwiftData selected. This generates the `MyPepTrackerApp.swift` with `ModelContainer`, a starter `ContentView.swift`, and test targets.

- [ ] **Step 2: Create AppTheme with Clinical Clean palette**

Create `MyPepTracker/Theme/AppTheme.swift`:

```swift
import SwiftUI

enum AppTheme {
    // MARK: - Colors
    static let background = Color(red: 0.94, green: 0.97, blue: 1.0)       // #f0f9ff
    static let surface = Color.white
    static let primary = Color(red: 0.23, green: 0.51, blue: 0.96)         // #3b82f6
    static let success = Color(red: 0.06, green: 0.73, blue: 0.51)         // #10b981
    static let warning = Color(red: 0.96, green: 0.62, blue: 0.04)         // #f59e0b
    static let danger = Color(red: 0.94, green: 0.27, blue: 0.27)          // #ef4444
    static let textPrimary = Color(red: 0.12, green: 0.16, blue: 0.21)     // #1e293b
    static let textSecondary = Color(red: 0.39, green: 0.45, blue: 0.55)   // #64748b

    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24

    // MARK: - Shape
    static let cornerRadius: CGFloat = 12
    static let cardShadowRadius: CGFloat = 4
    static let cardShadowY: CGFloat = 2
}
```

- [ ] **Step 3: Verify project builds**

```bash
cd ~/repos/peptide-tracker
xcodebuild -project MyPepTracker.xcodeproj -scheme MyPepTracker -destination 'platform=iOS Simulator,name=iPhone 16' build 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 4: Initialize git and commit**

```bash
cd ~/repos/peptide-tracker
git init
echo ".DS_Store\n*.xcuserdata\nbuild/\n.superpowers/" > .gitignore
git add .
git commit -m "feat: scaffold MyPepTracker Xcode project with Clinical Clean theme"
```

---

### Task 2: Enums and Concentration Calculator

**Files:**
- Create: `MyPepTracker/Models/ScheduleType.swift`
- Create: `MyPepTracker/Models/InjectionSite.swift`
- Create: `MyPepTracker/Services/ConcentrationCalculator.swift`
- Create: `MyPepTrackerTests/ConcentrationCalculatorTests.swift`

- [ ] **Step 1: Create ScheduleType enum**

Create `MyPepTracker/Models/ScheduleType.swift`:

```swift
import Foundation

enum ScheduleType: String, Codable, CaseIterable {
    case fixedRecurring
    case afterDose

    var displayName: String {
        switch self {
        case .fixedRecurring: "Fixed Schedule"
        case .afterDose: "After Last Dose"
        }
    }
}
```

- [ ] **Step 2: Create InjectionSite enum**

Create `MyPepTracker/Models/InjectionSite.swift`:

```swift
import Foundation

enum InjectionSite: String, Codable, CaseIterable {
    case abdomen
    case thighLeft
    case thighRight
    case deltoidLeft
    case deltoidRight
    case gluteLeft
    case gluteRight
    case other

    var displayName: String {
        switch self {
        case .abdomen: "Abdomen"
        case .thighLeft: "Left Thigh"
        case .thighRight: "Right Thigh"
        case .deltoidLeft: "Left Deltoid"
        case .deltoidRight: "Right Deltoid"
        case .gluteLeft: "Left Glute"
        case .gluteRight: "Right Glute"
        case .other: "Other"
        }
    }
}
```

- [ ] **Step 3: Write failing tests for ConcentrationCalculator**

Create `MyPepTrackerTests/ConcentrationCalculatorTests.swift`:

```swift
import Testing
@testable import MyPepTracker

struct ConcentrationCalculatorTests {
    // 5mg peptide in 2mL water = 2500 mcg/mL
    @Test func concentrationFromStandardReconstitution() {
        let result = ConcentrationCalculator.concentrationMcgPerML(
            peptideAmountMg: 5.0,
            waterVolumeML: 2.0
        )
        #expect(result == 2500.0)
    }

    // 10mg peptide in 1mL water = 10000 mcg/mL
    @Test func concentrationFromHighConcentration() {
        let result = ConcentrationCalculator.concentrationMcgPerML(
            peptideAmountMg: 10.0,
            waterVolumeML: 1.0
        )
        #expect(result == 10000.0)
    }

    // 250mcg dose at 2500 mcg/mL = 0.1 mL
    @Test func unitsForDose() {
        let result = ConcentrationCalculator.volumeMLForDose(
            doseMcg: 250.0,
            concentrationMcgPerML: 2500.0
        )
        #expect(result == 0.1)
    }

    // 0.1 mL in insulin units (U-100) = 10 IU
    @Test func insulinUnitsFromML() {
        let result = ConcentrationCalculator.insulinUnits(fromML: 0.1)
        #expect(result == 10.0)
    }

    // Remaining doses: 2mL vial, 0.3mL used, dose = 250mcg at 2500mcg/mL (0.1mL per dose)
    // remaining = 2.0 - 0.3 = 1.7mL, doses = 1.7 / 0.1 = 17
    @Test func estimatedRemainingDoses() {
        let result = ConcentrationCalculator.estimatedRemainingDoses(
            totalVolumeML: 2.0,
            usedVolumeML: 0.3,
            doseMcg: 250.0,
            concentrationMcgPerML: 2500.0
        )
        #expect(result == 17)
    }
}
```

- [ ] **Step 4: Run tests to verify they fail**

```bash
xcodebuild test -project MyPepTracker.xcodeproj -scheme MyPepTracker -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(Test|error|FAIL)"
```

Expected: Compilation errors — `ConcentrationCalculator` does not exist.

- [ ] **Step 5: Implement ConcentrationCalculator**

Create `MyPepTracker/Services/ConcentrationCalculator.swift`:

```swift
import Foundation

enum ConcentrationCalculator {
    /// Calculates concentration in mcg per mL.
    /// - Parameters:
    ///   - peptideAmountMg: Amount of peptide in the vial (mg)
    ///   - waterVolumeML: Volume of BAC water added (mL)
    /// - Returns: Concentration in mcg/mL
    static func concentrationMcgPerML(peptideAmountMg: Double, waterVolumeML: Double) -> Double {
        (peptideAmountMg * 1000.0) / waterVolumeML
    }

    /// Calculates the volume in mL needed for a given dose.
    static func volumeMLForDose(doseMcg: Double, concentrationMcgPerML: Double) -> Double {
        doseMcg / concentrationMcgPerML
    }

    /// Converts mL to insulin units (U-100: 1 mL = 100 IU).
    static func insulinUnits(fromML ml: Double) -> Double {
        ml * 100.0
    }

    /// Estimates how many doses remain in a vial.
    static func estimatedRemainingDoses(
        totalVolumeML: Double,
        usedVolumeML: Double,
        doseMcg: Double,
        concentrationMcgPerML: Double
    ) -> Int {
        let remainingML = totalVolumeML - usedVolumeML
        let mlPerDose = volumeMLForDose(doseMcg: doseMcg, concentrationMcgPerML: concentrationMcgPerML)
        return Int(remainingML / mlPerDose)
    }
}
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
xcodebuild test -project MyPepTracker.xcodeproj -scheme MyPepTracker -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(Test|PASS|FAIL)"
```

Expected: All 5 tests PASS.

- [ ] **Step 7: Commit**

```bash
git add .
git commit -m "feat: add enums and ConcentrationCalculator with tests"
```

---

### Task 3: SwiftData Models

**Files:**
- Create: `MyPepTracker/Models/Peptide.swift`
- Create: `MyPepTracker/Models/Vial.swift`
- Create: `MyPepTracker/Models/DoseEntry.swift`
- Create: `MyPepTrackerTests/VialTests.swift`
- Modify: `MyPepTracker/MyPepTrackerApp.swift`

- [ ] **Step 1: Write failing tests for Vial derived properties**

Create `MyPepTrackerTests/VialTests.swift`:

```swift
import Testing
import Foundation
@testable import MyPepTracker

struct VialTests {
    @Test func expiryDateCalculation() {
        let mixed = Date(timeIntervalSince1970: 1_700_000_000) // fixed date
        let vial = Vial(
            peptideAmountMg: 5.0,
            waterVolumeML: 2.0,
            dateMixed: mixed,
            expiryDays: 30
        )
        let expected = Calendar.current.date(byAdding: .day, value: 30, to: mixed)!
        #expect(vial.expiryDate == expected)
    }

    @Test func isExpiredWhenPastExpiry() {
        let mixed = Calendar.current.date(byAdding: .day, value: -31, to: Date())!
        let vial = Vial(
            peptideAmountMg: 5.0,
            waterVolumeML: 2.0,
            dateMixed: mixed,
            expiryDays: 30
        )
        #expect(vial.isExpired == true)
    }

    @Test func isNotExpiredWhenFresh() {
        let vial = Vial(
            peptideAmountMg: 5.0,
            waterVolumeML: 2.0,
            dateMixed: Date(),
            expiryDays: 30
        )
        #expect(vial.isExpired == false)
    }

    @Test func concentrationAutoCalculated() {
        let vial = Vial(
            peptideAmountMg: 5.0,
            waterVolumeML: 2.0,
            dateMixed: Date(),
            expiryDays: 30
        )
        #expect(vial.concentrationMcgPerML == 2500.0)
    }

    @Test func remainingVolumeAfterUsage() {
        let vial = Vial(
            peptideAmountMg: 5.0,
            waterVolumeML: 2.0,
            dateMixed: Date(),
            expiryDays: 30
        )
        vial.totalVolumeUsedML = 0.5
        #expect(vial.remainingVolumeML == 1.5)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Compilation errors — `Vial` does not exist.

- [ ] **Step 3: Create Peptide model**

Create `MyPepTracker/Models/Peptide.swift`:

```swift
import Foundation
import SwiftData

@Model
final class Peptide {
    var name: String
    var defaultDoseMcg: Double
    var scheduleType: ScheduleType
    var frequencyHours: Double
    var scheduledTime: Date?
    var scheduleDays: [Int]?
    var notes: String?
    var isActive: Bool

    @Relationship(deleteRule: .cascade, inverse: \Vial.peptide)
    var vials: [Vial] = []

    @Relationship(deleteRule: .cascade, inverse: \DoseEntry.peptide)
    var doseEntries: [DoseEntry] = []

    var activeVial: Vial? {
        vials.first { $0.isActive && !$0.isExpired }
    }

    var lastDose: DoseEntry? {
        doseEntries.sorted { $0.timestamp > $1.timestamp }.first
    }

    init(
        name: String,
        defaultDoseMcg: Double,
        scheduleType: ScheduleType,
        frequencyHours: Double,
        scheduledTime: Date? = nil,
        scheduleDays: [Int]? = nil,
        notes: String? = nil,
        isActive: Bool = true
    ) {
        self.name = name
        self.defaultDoseMcg = defaultDoseMcg
        self.scheduleType = scheduleType
        self.frequencyHours = frequencyHours
        self.scheduledTime = scheduledTime
        self.scheduleDays = scheduleDays
        self.notes = notes
        self.isActive = isActive
    }
}
```

- [ ] **Step 4: Create Vial model**

Create `MyPepTracker/Models/Vial.swift`:

```swift
import Foundation
import SwiftData

@Model
final class Vial {
    var peptideAmountMg: Double
    var waterVolumeML: Double
    var dateMixed: Date
    var expiryDays: Int
    var totalVolumeUsedML: Double
    var isActive: Bool

    var peptide: Peptide?

    @Relationship(deleteRule: .cascade, inverse: \DoseEntry.vial)
    var doseEntries: [DoseEntry] = []

    var concentrationMcgPerML: Double {
        ConcentrationCalculator.concentrationMcgPerML(
            peptideAmountMg: peptideAmountMg,
            waterVolumeML: waterVolumeML
        )
    }

    var expiryDate: Date {
        Calendar.current.date(byAdding: .day, value: expiryDays, to: dateMixed)!
    }

    var isExpired: Bool {
        expiryDate < Date()
    }

    var remainingVolumeML: Double {
        waterVolumeML - totalVolumeUsedML
    }

    var daysUntilExpiry: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: expiryDate).day ?? 0
    }

    func estimatedRemainingDoses(forDoseMcg doseMcg: Double) -> Int {
        ConcentrationCalculator.estimatedRemainingDoses(
            totalVolumeML: waterVolumeML,
            usedVolumeML: totalVolumeUsedML,
            doseMcg: doseMcg,
            concentrationMcgPerML: concentrationMcgPerML
        )
    }

    init(
        peptideAmountMg: Double,
        waterVolumeML: Double,
        dateMixed: Date = Date(),
        expiryDays: Int = 30,
        totalVolumeUsedML: Double = 0,
        isActive: Bool = true
    ) {
        self.peptideAmountMg = peptideAmountMg
        self.waterVolumeML = waterVolumeML
        self.dateMixed = dateMixed
        self.expiryDays = expiryDays
        self.totalVolumeUsedML = totalVolumeUsedML
        self.isActive = isActive
    }
}
```

- [ ] **Step 5: Create DoseEntry model**

Create `MyPepTracker/Models/DoseEntry.swift`:

```swift
import Foundation
import SwiftData

@Model
final class DoseEntry {
    var timestamp: Date
    var doseMcg: Double
    var unitsInjectedML: Double
    var injectionSite: InjectionSite?
    var notes: String?

    var peptide: Peptide?
    var vial: Vial?

    init(
        timestamp: Date = Date(),
        doseMcg: Double,
        unitsInjectedML: Double,
        injectionSite: InjectionSite? = nil,
        notes: String? = nil
    ) {
        self.timestamp = timestamp
        self.doseMcg = doseMcg
        self.unitsInjectedML = unitsInjectedML
        self.injectionSite = injectionSite
        self.notes = notes
    }
}
```

- [ ] **Step 6: Update MyPepTrackerApp to register all models**

Modify `MyPepTracker/MyPepTrackerApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct MyPepTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Peptide.self, Vial.self, DoseEntry.self])
    }
}
```

- [ ] **Step 7: Run tests to verify they pass**

```bash
xcodebuild test -project MyPepTracker.xcodeproj -scheme MyPepTracker -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(Test|PASS|FAIL)"
```

Expected: All Vial and ConcentrationCalculator tests PASS.

- [ ] **Step 8: Commit**

```bash
git add .
git commit -m "feat: add SwiftData models (Peptide, Vial, DoseEntry) with tests"
```

---

### Task 4: Peptide Preset Library

**Files:**
- Create: `MyPepTracker/Models/PeptidePreset.swift`
- Create: `MyPepTracker/Resources/peptide-presets.json`
- Create: `MyPepTrackerTests/PeptidePresetTests.swift`

- [ ] **Step 1: Write failing tests for preset loading**

Create `MyPepTrackerTests/PeptidePresetTests.swift`:

```swift
import Testing
import Foundation
@testable import MyPepTracker

struct PeptidePresetTests {
    @Test func loadPresetsFromBundle() throws {
        let presets = try PeptidePreset.loadAll()
        #expect(presets.count > 0)
    }

    @Test func presetsHaveRequiredFields() throws {
        let presets = try PeptidePreset.loadAll()
        for preset in presets {
            #expect(!preset.name.isEmpty)
            #expect(preset.typicalDoseMcgLow > 0)
            #expect(preset.typicalDoseMcgHigh >= preset.typicalDoseMcgLow)
            #expect(preset.typicalVialSizeMg > 0)
            #expect(preset.commonFrequencyHours > 0)
            #expect(!preset.category.isEmpty)
        }
    }

    @Test func presetsGroupByCategory() throws {
        let presets = try PeptidePreset.loadAll()
        let grouped = PeptidePreset.groupedByCategory(presets)
        #expect(grouped.keys.count > 0)
        for (_, items) in grouped {
            #expect(items.count > 0)
        }
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Compilation errors — `PeptidePreset` does not exist.

- [ ] **Step 3: Create PeptidePreset struct**

Create `MyPepTracker/Models/PeptidePreset.swift`:

```swift
import Foundation

struct PeptidePreset: Codable, Identifiable {
    var id: String { name }
    let name: String
    let typicalDoseMcgLow: Double
    let typicalDoseMcgHigh: Double
    let typicalVialSizeMg: Double
    let commonFrequencyHours: Double
    let category: String

    static func loadAll() throws -> [PeptidePreset] {
        guard let url = Bundle.main.url(forResource: "peptide-presets", withExtension: "json") else {
            throw PresetError.fileNotFound
        }
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([PeptidePreset].self, from: data)
    }

    static func groupedByCategory(_ presets: [PeptidePreset]) -> [String: [PeptidePreset]] {
        Dictionary(grouping: presets, by: \.category)
    }

    enum PresetError: Error {
        case fileNotFound
    }
}
```

- [ ] **Step 4: Create the preset JSON catalog**

Create `MyPepTracker/Resources/peptide-presets.json`:

```json
[
  {
    "name": "BPC-157",
    "typicalDoseMcgLow": 200,
    "typicalDoseMcgHigh": 500,
    "typicalVialSizeMg": 5,
    "commonFrequencyHours": 24,
    "category": "Healing"
  },
  {
    "name": "TB-500",
    "typicalDoseMcgLow": 2000,
    "typicalDoseMcgHigh": 5000,
    "typicalVialSizeMg": 5,
    "commonFrequencyHours": 168,
    "category": "Healing"
  },
  {
    "name": "Semaglutide",
    "typicalDoseMcgLow": 250,
    "typicalDoseMcgHigh": 2500,
    "typicalVialSizeMg": 5,
    "commonFrequencyHours": 168,
    "category": "Weight Management"
  },
  {
    "name": "Tirzepatide",
    "typicalDoseMcgLow": 2500,
    "typicalDoseMcgHigh": 15000,
    "typicalVialSizeMg": 10,
    "commonFrequencyHours": 168,
    "category": "Weight Management"
  },
  {
    "name": "CJC-1295 / Ipamorelin",
    "typicalDoseMcgLow": 100,
    "typicalDoseMcgHigh": 300,
    "typicalVialSizeMg": 5,
    "commonFrequencyHours": 24,
    "category": "GH Secretagogue"
  },
  {
    "name": "Tesamorelin",
    "typicalDoseMcgLow": 1000,
    "typicalDoseMcgHigh": 2000,
    "typicalVialSizeMg": 5,
    "commonFrequencyHours": 24,
    "category": "GH Secretagogue"
  },
  {
    "name": "MK-677 (Ibutamoren)",
    "typicalDoseMcgLow": 10000,
    "typicalDoseMcgHigh": 25000,
    "typicalVialSizeMg": 25,
    "commonFrequencyHours": 24,
    "category": "GH Secretagogue"
  },
  {
    "name": "PT-141",
    "typicalDoseMcgLow": 500,
    "typicalDoseMcgHigh": 2000,
    "typicalVialSizeMg": 10,
    "commonFrequencyHours": 72,
    "category": "Other"
  },
  {
    "name": "KPV",
    "typicalDoseMcgLow": 200,
    "typicalDoseMcgHigh": 600,
    "typicalVialSizeMg": 5,
    "commonFrequencyHours": 24,
    "category": "Anti-Inflammatory"
  },
  {
    "name": "GHK-Cu",
    "typicalDoseMcgLow": 100,
    "typicalDoseMcgHigh": 200,
    "typicalVialSizeMg": 5,
    "commonFrequencyHours": 24,
    "category": "Anti-Aging"
  }
]
```

**Important:** Add this JSON file to the Xcode project's target so it's included in the app bundle. In Xcode: File > Add Files > select `peptide-presets.json` > check "Copy items if needed" and "Add to targets: MyPepTracker".

- [ ] **Step 5: Run tests to verify they pass**

```bash
xcodebuild test -project MyPepTracker.xcodeproj -scheme MyPepTracker -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(Test|PASS|FAIL)"
```

Expected: All PeptidePreset tests PASS.

- [ ] **Step 6: Commit**

```bash
git add .
git commit -m "feat: add peptide preset library with bundled JSON catalog"
```

---

### Task 5: NotificationManager

**Files:**
- Create: `MyPepTracker/Services/NotificationManager.swift`
- Create: `MyPepTrackerTests/NotificationManagerTests.swift`

- [ ] **Step 1: Write failing tests for notification scheduling logic**

Create `MyPepTrackerTests/NotificationManagerTests.swift`:

```swift
import Testing
import Foundation
@testable import MyPepTracker

struct NotificationManagerTests {
    @Test func doseReminderIdentifier() {
        let id = NotificationManager.doseReminderID(peptideName: "BPC-157")
        #expect(id == "dose-reminder-BPC-157")
    }

    @Test func overdueIdentifier() {
        let id = NotificationManager.overdueReminderID(peptideName: "BPC-157")
        #expect(id == "overdue-BPC-157")
    }

    @Test func vialExpiryIdentifier() {
        let id = NotificationManager.vialExpiryID(peptideName: "BPC-157")
        #expect(id == "vial-expiry-BPC-157")
    }

    @Test func vialLowIdentifier() {
        let id = NotificationManager.vialLowID(peptideName: "BPC-157")
        #expect(id == "vial-low-BPC-157")
    }

    @Test func nextDoseDateForAfterDoseSchedule() {
        let lastDose = Date(timeIntervalSince1970: 1_700_000_000)
        let next = NotificationManager.nextDoseDate(
            scheduleType: .afterDose,
            frequencyHours: 48,
            lastDoseTimestamp: lastDose,
            scheduledTime: nil,
            scheduleDays: nil
        )
        let expected = lastDose.addingTimeInterval(48 * 3600)
        #expect(next == expected)
    }

    @Test func nextDoseDateReturnsNilForAfterDoseWithNoHistory() {
        let next = NotificationManager.nextDoseDate(
            scheduleType: .afterDose,
            frequencyHours: 48,
            lastDoseTimestamp: nil,
            scheduledTime: nil,
            scheduleDays: nil
        )
        #expect(next == nil)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Expected: Compilation errors — `NotificationManager` does not exist.

- [ ] **Step 3: Implement NotificationManager**

Create `MyPepTracker/Services/NotificationManager.swift`:

```swift
import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private let center = UNUserNotificationCenter.current()

    private init() {}

    // MARK: - Permission

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Identifiers

    static func doseReminderID(peptideName: String) -> String {
        "dose-reminder-\(peptideName)"
    }

    static func overdueReminderID(peptideName: String) -> String {
        "overdue-\(peptideName)"
    }

    static func vialExpiryID(peptideName: String) -> String {
        "vial-expiry-\(peptideName)"
    }

    static func vialLowID(peptideName: String) -> String {
        "vial-low-\(peptideName)"
    }

    // MARK: - Scheduling Logic

    static func nextDoseDate(
        scheduleType: ScheduleType,
        frequencyHours: Double,
        lastDoseTimestamp: Date?,
        scheduledTime: Date?,
        scheduleDays: [Int]?
    ) -> Date? {
        switch scheduleType {
        case .afterDose:
            guard let lastDose = lastDoseTimestamp else { return nil }
            return lastDose.addingTimeInterval(frequencyHours * 3600)

        case .fixedRecurring:
            guard let time = scheduledTime else { return nil }
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

            if let days = scheduleDays, !days.isEmpty {
                // Find the next matching weekday
                let now = Date()
                let todayWeekday = calendar.component(.weekday, from: now)
                let sortedDays = days.sorted()

                for dayOffset in 0..<8 {
                    let candidateDate = calendar.date(byAdding: .day, value: dayOffset, to: now)!
                    let candidateWeekday = calendar.component(.weekday, from: candidateDate)
                    if sortedDays.contains(candidateWeekday) {
                        var components = calendar.dateComponents([.year, .month, .day], from: candidateDate)
                        components.hour = timeComponents.hour
                        components.minute = timeComponents.minute
                        if let date = calendar.date(from: components), date > now {
                            return date
                        }
                    }
                }
            }

            // Daily: next occurrence of the scheduled time
            var components = calendar.dateComponents([.year, .month, .day], from: Date())
            components.hour = timeComponents.hour
            components.minute = timeComponents.minute
            if let date = calendar.date(from: components), date > Date() {
                return date
            }
            return calendar.date(byAdding: .day, value: 1, to: calendar.date(from: components)!)
        }
    }

    // MARK: - Schedule Dose Reminder

    func scheduleDoseReminder(for peptide: Peptide) {
        let id = Self.doseReminderID(peptideName: peptide.name)
        center.removePendingNotificationRequests(withIdentifiers: [id])

        guard let nextDate = Self.nextDoseDate(
            scheduleType: peptide.scheduleType,
            frequencyHours: peptide.frequencyHours,
            lastDoseTimestamp: peptide.lastDose?.timestamp,
            scheduledTime: peptide.scheduledTime,
            scheduleDays: peptide.scheduleDays
        ) else { return }

        let content = UNMutableNotificationContent()
        content.title = "Time to take your \(peptide.name)"
        content.body = "\(Int(peptide.defaultDoseMcg))mcg dose"
        content.sound = .default
        content.categoryIdentifier = "DOSE_REMINDER"

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, nextDate.timeIntervalSinceNow),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Schedule Overdue Reminder

    func scheduleOverdueReminder(for peptide: Peptide, overdueDelayHours: Double = 2.0) {
        let id = Self.overdueReminderID(peptideName: peptide.name)
        center.removePendingNotificationRequests(withIdentifiers: [id])

        guard let nextDate = Self.nextDoseDate(
            scheduleType: peptide.scheduleType,
            frequencyHours: peptide.frequencyHours,
            lastDoseTimestamp: peptide.lastDose?.timestamp,
            scheduledTime: peptide.scheduledTime,
            scheduleDays: peptide.scheduleDays
        ) else { return }

        let overdueDate = nextDate.addingTimeInterval(overdueDelayHours * 3600)

        let content = UNMutableNotificationContent()
        content.title = "Missed \(peptide.name) dose"
        content.body = "Your dose was scheduled earlier — log it when you can."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, overdueDate.timeIntervalSinceNow),
            repeats: false
        )
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Schedule Vial Expiry Warning

    func scheduleVialExpiryWarning(for peptide: Peptide, vial: Vial, warningDays: Int = 3) {
        let id = Self.vialExpiryID(peptideName: peptide.name)
        center.removePendingNotificationRequests(withIdentifiers: [id])

        let warningDate = Calendar.current.date(byAdding: .day, value: -warningDays, to: vial.expiryDate)!
        guard warningDate > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = "\(peptide.name) vial expiring"
        content.body = "Your vial expires in \(warningDays) days — consider reconstituting a new one."
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: warningDate.timeIntervalSinceNow,
            repeats: false
        )
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    // MARK: - Vial Low Warning

    func scheduleVialLowWarning(for peptide: Peptide, remainingDoses: Int) {
        let id = Self.vialLowID(peptideName: peptide.name)
        if remainingDoses <= 2 {
            let content = UNMutableNotificationContent()
            content.title = "\(peptide.name) vial running low"
            content.body = "Approximately \(remainingDoses) doses remaining."
            content.sound = .default

            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
            let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
            center.add(request)
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [id])
        }
    }

    // MARK: - Cancel All for Peptide

    func cancelAll(for peptide: Peptide) {
        let ids = [
            Self.doseReminderID(peptideName: peptide.name),
            Self.overdueReminderID(peptideName: peptide.name),
            Self.vialExpiryID(peptideName: peptide.name),
            Self.vialLowID(peptideName: peptide.name),
        ]
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Register Actions

    func registerCategories() {
        let logAction = UNNotificationAction(
            identifier: "LOG_DOSE",
            title: "Log Dose",
            options: [.foreground]
        )
        let category = UNNotificationCategory(
            identifier: "DOSE_REMINDER",
            actions: [logAction],
            intentIdentifiers: []
        )
        center.setNotificationCategories([category])
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -project MyPepTracker.xcodeproj -scheme MyPepTracker -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(Test|PASS|FAIL)"
```

Expected: All NotificationManager tests PASS.

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "feat: add NotificationManager with dose, overdue, expiry, and low-vial alerts"
```

---

### Task 6: Tab Navigation and Today View

**Files:**
- Modify: `MyPepTracker/ContentView.swift`
- Create: `MyPepTracker/Views/Today/TodayView.swift`
- Create: `MyPepTracker/Views/Today/PeptideCardView.swift`
- Create: `MyPepTracker/Views/Today/LogDoseSheet.swift`
- Create: `MyPepTracker/Views/Peptides/PeptideListView.swift` (placeholder)
- Create: `MyPepTracker/Views/History/HistoryView.swift` (placeholder)
- Create: `MyPepTracker/Views/Settings/SettingsView.swift` (placeholder)

- [ ] **Step 1: Set up TabView in ContentView**

Replace `MyPepTracker/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "pill.fill")
                }

            PeptideListView()
                .tabItem {
                    Label("Peptides", systemImage: "cube.box.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "list.clipboard.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(AppTheme.primary)
    }
}
```

- [ ] **Step 2: Create placeholder views for tabs 2-4**

Create `MyPepTracker/Views/Peptides/PeptideListView.swift`:

```swift
import SwiftUI

struct PeptideListView: View {
    var body: some View {
        NavigationStack {
            Text("Peptides")
                .navigationTitle("Peptides")
        }
    }
}
```

Create `MyPepTracker/Views/History/HistoryView.swift`:

```swift
import SwiftUI

struct HistoryView: View {
    var body: some View {
        NavigationStack {
            Text("History")
                .navigationTitle("History")
        }
    }
}
```

Create `MyPepTracker/Views/Settings/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        NavigationStack {
            Text("Settings")
                .navigationTitle("Settings")
        }
    }
}
```

- [ ] **Step 3: Create PeptideCardView**

Create `MyPepTracker/Views/Today/PeptideCardView.swift`:

```swift
import SwiftUI

struct PeptideCardView: View {
    let peptide: Peptide
    let onLogDose: () -> Void

    private var nextDoseDate: Date? {
        NotificationManager.nextDoseDate(
            scheduleType: peptide.scheduleType,
            frequencyHours: peptide.frequencyHours,
            lastDoseTimestamp: peptide.lastDose?.timestamp,
            scheduledTime: peptide.scheduledTime,
            scheduleDays: peptide.scheduleDays
        )
    }

    private var isOverdue: Bool {
        guard let next = nextDoseDate else { return false }
        return next < Date()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSmall) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(peptide.name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("\(Int(peptide.defaultDoseMcg))mcg • \(peptide.scheduleType.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Button(action: onLogDose) {
                    Text("Log Dose")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(AppTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }

            // Next dose info
            if let next = nextDoseDate {
                HStack(spacing: 6) {
                    Image(systemName: isOverdue ? "exclamationmark.circle.fill" : "clock.fill")
                        .foregroundStyle(isOverdue ? AppTheme.danger : AppTheme.textSecondary)
                        .font(.caption)
                    Text(isOverdue ? "Overdue" : "Next: \(next, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(isOverdue ? AppTheme.danger : AppTheme.textSecondary)
                }
            }

            // Vial status
            if let vial = peptide.activeVial {
                HStack(spacing: 12) {
                    Label(
                        "\(vial.daysUntilExpiry)d left",
                        systemImage: "flask.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(vial.daysUntilExpiry <= 3 ? AppTheme.warning : AppTheme.textSecondary)

                    let remaining = vial.estimatedRemainingDoses(forDoseMcg: peptide.defaultDoseMcg)
                    Label(
                        "~\(remaining) doses",
                        systemImage: "syringe.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(remaining <= 2 ? AppTheme.warning : AppTheme.textSecondary)
                }
            } else {
                Text("No active vial")
                    .font(.caption)
                    .foregroundStyle(AppTheme.warning)
            }
        }
        .padding(AppTheme.paddingMedium)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: .black.opacity(0.06), radius: AppTheme.cardShadowRadius, y: AppTheme.cardShadowY)
    }
}
```

- [ ] **Step 4: Create LogDoseSheet**

Create `MyPepTracker/Views/Today/LogDoseSheet.swift`:

```swift
import SwiftUI
import SwiftData

struct LogDoseSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let peptide: Peptide

    @State private var doseMcg: Double
    @State private var injectionSite: InjectionSite?
    @State private var notes: String = ""

    init(peptide: Peptide) {
        self.peptide = peptide
        self._doseMcg = State(initialValue: peptide.defaultDoseMcg)
        self._injectionSite = State(initialValue: peptide.lastDose?.injectionSite)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Dose") {
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("mcg", value: $doseMcg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("mcg")
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    if let vial = peptide.activeVial {
                        let volumeML = ConcentrationCalculator.volumeMLForDose(
                            doseMcg: doseMcg,
                            concentrationMcgPerML: vial.concentrationMcgPerML
                        )
                        let iu = ConcentrationCalculator.insulinUnits(fromML: volumeML)
                        HStack {
                            Text("Volume")
                            Spacer()
                            Text(String(format: "%.2f mL (%.0f IU)", volumeML, iu))
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }

                Section("Injection Site") {
                    Picker("Site", selection: $injectionSite) {
                        Text("None").tag(nil as InjectionSite?)
                        ForEach(InjectionSite.allCases, id: \.self) { site in
                            Text(site.displayName).tag(site as InjectionSite?)
                        }
                    }
                }

                Section("Notes") {
                    TextField("Optional observations...", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .navigationTitle("Log \(peptide.name)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Log") { logDose() }
                        .fontWeight(.semibold)
                        .disabled(peptide.activeVial == nil)
                }
            }
        }
    }

    private func logDose() {
        guard let vial = peptide.activeVial else { return }

        let volumeML = ConcentrationCalculator.volumeMLForDose(
            doseMcg: doseMcg,
            concentrationMcgPerML: vial.concentrationMcgPerML
        )

        let entry = DoseEntry(
            doseMcg: doseMcg,
            unitsInjectedML: volumeML,
            injectionSite: injectionSite,
            notes: notes.isEmpty ? nil : notes
        )
        entry.peptide = peptide
        entry.vial = vial

        vial.totalVolumeUsedML += volumeML

        modelContext.insert(entry)

        // Reschedule notifications
        let manager = NotificationManager.shared
        manager.scheduleDoseReminder(for: peptide)
        manager.scheduleOverdueReminder(for: peptide)

        let remaining = vial.estimatedRemainingDoses(forDoseMcg: peptide.defaultDoseMcg)
        manager.scheduleVialLowWarning(for: peptide, remainingDoses: remaining)

        dismiss()
    }
}
```

- [ ] **Step 5: Create TodayView**

Create `MyPepTracker/Views/Today/TodayView.swift`:

```swift
import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(filter: #Predicate<Peptide> { $0.isActive }, sort: \Peptide.name)
    private var activePeptides: [Peptide]

    @State private var peptideToLog: Peptide?

    var body: some View {
        NavigationStack {
            ScrollView {
                if activePeptides.isEmpty {
                    ContentUnavailableView(
                        "No Active Peptides",
                        systemImage: "pill.fill",
                        description: Text("Add a peptide from the Peptides tab to get started.")
                    )
                } else {
                    LazyVStack(spacing: AppTheme.paddingSmall) {
                        ForEach(activePeptides) { peptide in
                            PeptideCardView(peptide: peptide) {
                                peptideToLog = peptide
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.paddingMedium)
                    .padding(.top, AppTheme.paddingSmall)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("Today")
            .sheet(item: $peptideToLog) { peptide in
                LogDoseSheet(peptide: peptide)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}
```

- [ ] **Step 6: Build and verify the app launches with tabs**

```bash
xcodebuild build -project MyPepTracker.xcodeproj -scheme MyPepTracker -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 7: Commit**

```bash
git add .
git commit -m "feat: add TabView navigation, TodayView with PeptideCards, and LogDoseSheet"
```

---

### Task 7: Peptides Tab — List, Detail, Add, and Reconstitute

**Files:**
- Modify: `MyPepTracker/Views/Peptides/PeptideListView.swift`
- Create: `MyPepTracker/Views/Peptides/PeptideDetailView.swift`
- Create: `MyPepTracker/Views/Peptides/AddPeptideView.swift`
- Create: `MyPepTracker/Views/Peptides/ReconstitutionSheet.swift`

- [ ] **Step 1: Implement PeptideListView**

Replace `MyPepTracker/Views/Peptides/PeptideListView.swift`:

```swift
import SwiftUI
import SwiftData

struct PeptideListView: View {
    @Query(sort: \Peptide.name) private var allPeptides: [Peptide]
    @State private var showingAddPeptide = false

    private var activePeptides: [Peptide] { allPeptides.filter(\.isActive) }
    private var archivedPeptides: [Peptide] { allPeptides.filter { !$0.isActive } }

    var body: some View {
        NavigationStack {
            List {
                if !activePeptides.isEmpty {
                    Section("Active") {
                        ForEach(activePeptides) { peptide in
                            NavigationLink(value: peptide) {
                                PeptideRowView(peptide: peptide)
                            }
                        }
                    }
                }

                if !archivedPeptides.isEmpty {
                    Section("Archived") {
                        ForEach(archivedPeptides) { peptide in
                            NavigationLink(value: peptide) {
                                PeptideRowView(peptide: peptide)
                            }
                        }
                    }
                }

                if allPeptides.isEmpty {
                    ContentUnavailableView(
                        "No Peptides Yet",
                        systemImage: "cube.box.fill",
                        description: Text("Tap + to add your first peptide.")
                    )
                }
            }
            .navigationTitle("Peptides")
            .navigationDestination(for: Peptide.self) { peptide in
                PeptideDetailView(peptide: peptide)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddPeptide = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddPeptide) {
                AddPeptideView()
            }
        }
    }
}

struct PeptideRowView: View {
    let peptide: Peptide

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(peptide.name)
                .font(.body.weight(.medium))
            HStack(spacing: 8) {
                Text("\(Int(peptide.defaultDoseMcg))mcg")
                Text("•")
                Text(peptide.scheduleType.displayName)
            }
            .font(.caption)
            .foregroundStyle(AppTheme.textSecondary)
        }
        .padding(.vertical, 2)
    }
}
```

- [ ] **Step 2: Implement AddPeptideView**

Create `MyPepTracker/Views/Peptides/AddPeptideView.swift`:

```swift
import SwiftUI
import SwiftData

struct AddPeptideView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var defaultDoseMcg: Double = 250
    @State private var scheduleType: ScheduleType = .fixedRecurring
    @State private var frequencyHours: Double = 24
    @State private var scheduledTime = Calendar.current.date(
        bySettingHour: 8, minute: 0, second: 0, of: Date()
    )!
    @State private var notes = ""
    @State private var selectedPreset: PeptidePreset?
    @State private var showPresets = true

    private var presets: [PeptidePreset] {
        (try? PeptidePreset.loadAll()) ?? []
    }

    private var groupedPresets: [String: [PeptidePreset]] {
        PeptidePreset.groupedByCategory(presets)
    }

    var body: some View {
        NavigationStack {
            Form {
                if showPresets && !presets.isEmpty {
                    Section("Quick Start — Pick a Preset") {
                        ForEach(groupedPresets.keys.sorted(), id: \.self) { category in
                            DisclosureGroup(category) {
                                ForEach(groupedPresets[category]!) { preset in
                                    Button {
                                        applyPreset(preset)
                                    } label: {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(preset.name)
                                                .foregroundStyle(AppTheme.textPrimary)
                                            Text("\(Int(preset.typicalDoseMcgLow))–\(Int(preset.typicalDoseMcgHigh))mcg • \(Int(preset.commonFrequencyHours))hr")
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.textSecondary)
                                        }
                                    }
                                }
                            }
                        }

                        Button("Enter Custom Instead") {
                            showPresets = false
                        }
                        .foregroundStyle(AppTheme.primary)
                    }
                }

                Section("Peptide Info") {
                    TextField("Name", text: $name)
                    HStack {
                        Text("Default Dose")
                        Spacer()
                        TextField("mcg", value: $defaultDoseMcg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 100)
                        Text("mcg")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                Section("Schedule") {
                    Picker("Type", selection: $scheduleType) {
                        ForEach(ScheduleType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }

                    HStack {
                        Text("Every")
                        Spacer()
                        TextField("hours", value: $frequencyHours, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("hours")
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    if scheduleType == .fixedRecurring {
                        DatePicker("Time of Day", selection: $scheduledTime, displayedComponents: .hourAndMinute)
                    }
                }

                Section("Notes") {
                    TextField("Optional notes...", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }
            }
            .navigationTitle("Add Peptide")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { savePeptide() }
                        .fontWeight(.semibold)
                        .disabled(name.isEmpty)
                }
            }
        }
    }

    private func applyPreset(_ preset: PeptidePreset) {
        name = preset.name
        defaultDoseMcg = preset.typicalDoseMcgLow
        frequencyHours = preset.commonFrequencyHours
        showPresets = false
        selectedPreset = preset
    }

    private func savePeptide() {
        let peptide = Peptide(
            name: name,
            defaultDoseMcg: defaultDoseMcg,
            scheduleType: scheduleType,
            frequencyHours: frequencyHours,
            scheduledTime: scheduleType == .fixedRecurring ? scheduledTime : nil,
            notes: notes.isEmpty ? nil : notes
        )
        modelContext.insert(peptide)

        NotificationManager.shared.scheduleDoseReminder(for: peptide)
        NotificationManager.shared.scheduleOverdueReminder(for: peptide)

        dismiss()
    }
}
```

- [ ] **Step 3: Implement ReconstitutionSheet**

Create `MyPepTracker/Views/Peptides/ReconstitutionSheet.swift`:

```swift
import SwiftUI
import SwiftData

struct ReconstitutionSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let peptide: Peptide

    @State private var peptideAmountMg: Double = 5.0
    @State private var waterVolumeML: Double = 2.0
    @State private var expiryDays: Int = 30

    private var concentration: Double {
        guard waterVolumeML > 0 else { return 0 }
        return ConcentrationCalculator.concentrationMcgPerML(
            peptideAmountMg: peptideAmountMg,
            waterVolumeML: waterVolumeML
        )
    }

    private var doseVolume: Double {
        guard concentration > 0 else { return 0 }
        return ConcentrationCalculator.volumeMLForDose(
            doseMcg: peptide.defaultDoseMcg,
            concentrationMcgPerML: concentration
        )
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Vial Contents") {
                    HStack {
                        Text("Peptide Amount")
                        Spacer()
                        TextField("mg", value: $peptideAmountMg, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("mg")
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    HStack {
                        Text("BAC Water")
                        Spacer()
                        TextField("mL", value: $waterVolumeML, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                        Text("mL")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                Section("Calculated") {
                    HStack {
                        Text("Concentration")
                        Spacer()
                        Text(String(format: "%.0f mcg/mL", concentration))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    HStack {
                        Text("Per Dose (\(Int(peptide.defaultDoseMcg))mcg)")
                        Spacer()
                        Text(String(format: "%.2f mL (%.0f IU)", doseVolume, ConcentrationCalculator.insulinUnits(fromML: doseVolume)))
                            .foregroundStyle(AppTheme.textSecondary)
                    }

                    let estDoses = concentration > 0
                        ? ConcentrationCalculator.estimatedRemainingDoses(
                            totalVolumeML: waterVolumeML,
                            usedVolumeML: 0,
                            doseMcg: peptide.defaultDoseMcg,
                            concentrationMcgPerML: concentration
                        )
                        : 0
                    HStack {
                        Text("Estimated Doses")
                        Spacer()
                        Text("~\(estDoses)")
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }

                Section {
                    Stepper("Expires after \(expiryDays) days", value: $expiryDays, in: 7...90)
                }
            }
            .navigationTitle("New Vial")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveVial() }
                        .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveVial() {
        // Deactivate existing active vials
        for vial in peptide.vials where vial.isActive {
            vial.isActive = false
        }

        let vial = Vial(
            peptideAmountMg: peptideAmountMg,
            waterVolumeML: waterVolumeML,
            expiryDays: expiryDays
        )
        vial.peptide = peptide
        modelContext.insert(vial)

        NotificationManager.shared.scheduleVialExpiryWarning(for: peptide, vial: vial)

        dismiss()
    }
}
```

- [ ] **Step 4: Implement PeptideDetailView**

Create `MyPepTracker/Views/Peptides/PeptideDetailView.swift`:

```swift
import SwiftUI
import SwiftData

struct PeptideDetailView: View {
    @Bindable var peptide: Peptide
    @State private var showingReconstitution = false
    @State private var showingLogDose = false

    private var recentDoses: [DoseEntry] {
        peptide.doseEntries
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(20)
            .map { $0 }
    }

    var body: some View {
        List {
            // Schedule section
            Section("Schedule") {
                LabeledContent("Type", value: peptide.scheduleType.displayName)
                LabeledContent("Frequency", value: "\(Int(peptide.frequencyHours)) hours")
                LabeledContent("Default Dose", value: "\(Int(peptide.defaultDoseMcg)) mcg")
                Toggle("Active", isOn: $peptide.isActive)
            }

            // Active vial section
            Section("Active Vial") {
                if let vial = peptide.activeVial {
                    LabeledContent("Mixed", value: vial.dateMixed, format: .dateTime.month().day().year())
                    LabeledContent("Concentration", value: String(format: "%.0f mcg/mL", vial.concentrationMcgPerML))
                    LabeledContent("Expires", value: vial.expiryDate, format: .dateTime.month().day())
                    LabeledContent("Days Left", value: "\(vial.daysUntilExpiry)")
                    let remaining = vial.estimatedRemainingDoses(forDoseMcg: peptide.defaultDoseMcg)
                    LabeledContent("Doses Remaining", value: "~\(remaining)")
                } else {
                    Text("No active vial")
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Button("Reconstitute New Vial") {
                    showingReconstitution = true
                }
            }

            // Recent doses
            if !recentDoses.isEmpty {
                Section("Recent Doses") {
                    ForEach(recentDoses) { dose in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("\(Int(dose.doseMcg)) mcg")
                                    .font(.body.weight(.medium))
                                Spacer()
                                Text(dose.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            if let site = dose.injectionSite {
                                Text(site.displayName)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            if let notes = dose.notes {
                                Text(notes)
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                    .italic()
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }

            // Notes
            if let notes = peptide.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .navigationTitle(peptide.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Log Dose") { showingLogDose = true }
                    .disabled(peptide.activeVial == nil)
            }
        }
        .sheet(isPresented: $showingReconstitution) {
            ReconstitutionSheet(peptide: peptide)
        }
        .sheet(isPresented: $showingLogDose) {
            LogDoseSheet(peptide: peptide)
                .presentationDetents([.medium, .large])
        }
    }
}
```

- [ ] **Step 5: Build and verify**

```bash
xcodebuild build -project MyPepTracker.xcodeproj -scheme MyPepTracker -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 6: Commit**

```bash
git add .
git commit -m "feat: add Peptides tab with list, detail, add, and reconstitution views"
```

---

### Task 8: History Tab with Body Map

**Files:**
- Modify: `MyPepTracker/Views/History/HistoryView.swift`
- Create: `MyPepTracker/Views/History/DoseEntryRow.swift`
- Create: `MyPepTracker/Views/History/BodyMapView.swift`

- [ ] **Step 1: Create DoseEntryRow**

Create `MyPepTracker/Views/History/DoseEntryRow.swift`:

```swift
import SwiftUI

struct DoseEntryRow: View {
    let entry: DoseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.peptide?.name ?? "Unknown")
                    .font(.body.weight(.medium))
                Spacer()
                Text(entry.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(spacing: 12) {
                Text("\(Int(entry.doseMcg)) mcg")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                if let site = entry.injectionSite {
                    Label(site.displayName, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.primary)
                }
            }

            if let notes = entry.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
}
```

- [ ] **Step 2: Create BodyMapView**

Create `MyPepTracker/Views/History/BodyMapView.swift`:

```swift
import SwiftUI

struct BodyMapView: View {
    let recentDoses: [DoseEntry]

    private var siteCounts: [InjectionSite: Int] {
        var counts: [InjectionSite: Int] = [:]
        for dose in recentDoses {
            if let site = dose.injectionSite {
                counts[site, default: 0] += 1
            }
        }
        return counts
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Recent Injection Sites")
                .font(.headline)
                .padding(.top)

            ZStack {
                // Simple body outline
                bodyOutline

                // Site indicators
                ForEach(InjectionSite.allCases.filter { $0 != .other }, id: \.self) { site in
                    if let count = siteCounts[site], count > 0 {
                        Circle()
                            .fill(AppTheme.primary.opacity(min(1.0, Double(count) * 0.3)))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .position(position(for: site))
                    }
                }
            }
            .frame(width: 200, height: 340)
            .padding()

            // Legend
            if !siteCounts.isEmpty {
                HStack(spacing: 16) {
                    ForEach(siteCounts.sorted(by: { $0.value > $1.value }), id: \.key) { site, count in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(AppTheme.primary)
                                .frame(width: 8, height: 8)
                            Text("\(site.displayName): \(count)")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }
                .padding(.bottom)
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }

    private var bodyOutline: some View {
        // Simple geometric body silhouette
        Canvas { context, size in
            let midX = size.width / 2

            // Head
            let headRect = CGRect(x: midX - 15, y: 10, width: 30, height: 30)
            context.fill(Ellipse().path(in: headRect), with: .color(.gray.opacity(0.15)))

            // Torso
            let torso = Path { p in
                p.move(to: CGPoint(x: midX - 25, y: 45))
                p.addLine(to: CGPoint(x: midX + 25, y: 45))
                p.addLine(to: CGPoint(x: midX + 20, y: 160))
                p.addLine(to: CGPoint(x: midX - 20, y: 160))
                p.closeSubpath()
            }
            context.fill(torso, with: .color(.gray.opacity(0.15)))

            // Left arm
            let leftArm = Path { p in
                p.move(to: CGPoint(x: midX - 25, y: 50))
                p.addLine(to: CGPoint(x: midX - 45, y: 55))
                p.addLine(to: CGPoint(x: midX - 50, y: 130))
                p.addLine(to: CGPoint(x: midX - 38, y: 130))
                p.addLine(to: CGPoint(x: midX - 33, y: 60))
                p.closeSubpath()
            }
            context.fill(leftArm, with: .color(.gray.opacity(0.15)))

            // Right arm
            let rightArm = Path { p in
                p.move(to: CGPoint(x: midX + 25, y: 50))
                p.addLine(to: CGPoint(x: midX + 45, y: 55))
                p.addLine(to: CGPoint(x: midX + 50, y: 130))
                p.addLine(to: CGPoint(x: midX + 38, y: 130))
                p.addLine(to: CGPoint(x: midX + 33, y: 60))
                p.closeSubpath()
            }
            context.fill(rightArm, with: .color(.gray.opacity(0.15)))

            // Left leg
            let leftLeg = Path { p in
                p.move(to: CGPoint(x: midX - 18, y: 160))
                p.addLine(to: CGPoint(x: midX - 22, y: 300))
                p.addLine(to: CGPoint(x: midX - 8, y: 300))
                p.addLine(to: CGPoint(x: midX - 3, y: 160))
                p.closeSubpath()
            }
            context.fill(leftLeg, with: .color(.gray.opacity(0.15)))

            // Right leg
            let rightLeg = Path { p in
                p.move(to: CGPoint(x: midX + 18, y: 160))
                p.addLine(to: CGPoint(x: midX + 22, y: 300))
                p.addLine(to: CGPoint(x: midX + 8, y: 300))
                p.addLine(to: CGPoint(x: midX + 3, y: 160))
                p.closeSubpath()
            }
            context.fill(rightLeg, with: .color(.gray.opacity(0.15)))
        }
    }

    private func position(for site: InjectionSite) -> CGPoint {
        let midX: CGFloat = 100
        switch site {
        case .abdomen:       return CGPoint(x: midX, y: 120)
        case .thighLeft:     return CGPoint(x: midX - 12, y: 220)
        case .thighRight:    return CGPoint(x: midX + 12, y: 220)
        case .deltoidLeft:   return CGPoint(x: midX - 42, y: 70)
        case .deltoidRight:  return CGPoint(x: midX + 42, y: 70)
        case .gluteLeft:     return CGPoint(x: midX - 18, y: 165)
        case .gluteRight:    return CGPoint(x: midX + 18, y: 165)
        case .other:         return CGPoint(x: midX, y: 310)
        }
    }
}
```

- [ ] **Step 3: Implement HistoryView**

Replace `MyPepTracker/Views/History/HistoryView.swift`:

```swift
import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \DoseEntry.timestamp, order: .reverse) private var allDoses: [DoseEntry]
    @Query(sort: \Peptide.name) private var allPeptides: [Peptide]

    @State private var selectedPeptide: Peptide?
    @State private var showBodyMap = false

    private var filteredDoses: [DoseEntry] {
        if let selected = selectedPeptide {
            return allDoses.filter { $0.peptide?.persistentModelID == selected.persistentModelID }
        }
        return Array(allDoses)
    }

    private var last30DaysDoses: [DoseEntry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date())!
        return allDoses.filter { $0.timestamp > cutoff }
    }

    var body: some View {
        NavigationStack {
            List {
                // Filter picker
                if allPeptides.count > 1 {
                    Section {
                        Picker("Filter", selection: $selectedPeptide) {
                            Text("All Peptides").tag(nil as Peptide?)
                            ForEach(allPeptides) { peptide in
                                Text(peptide.name).tag(peptide as Peptide?)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                }

                // Body map toggle
                if !allDoses.isEmpty {
                    Section {
                        Button {
                            showBodyMap.toggle()
                        } label: {
                            Label(
                                showBodyMap ? "Hide Body Map" : "Show Injection Sites",
                                systemImage: "figure.stand"
                            )
                        }

                        if showBodyMap {
                            BodyMapView(recentDoses: last30DaysDoses)
                        }
                    }
                }

                // Dose entries
                if filteredDoses.isEmpty {
                    ContentUnavailableView(
                        "No Dose History",
                        systemImage: "list.clipboard.fill",
                        description: Text("Logged doses will appear here.")
                    )
                } else {
                    Section("Doses") {
                        ForEach(filteredDoses) { dose in
                            DoseEntryRow(entry: dose)
                        }
                    }
                }
            }
            .navigationTitle("History")
        }
    }
}
```

- [ ] **Step 4: Build and verify**

```bash
xcodebuild build -project MyPepTracker.xcodeproj -scheme MyPepTracker -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 5: Commit**

```bash
git add .
git commit -m "feat: add History tab with dose timeline, filtering, and body map"
```

---

### Task 9: Settings Tab

**Files:**
- Modify: `MyPepTracker/Views/Settings/SettingsView.swift`

- [ ] **Step 1: Implement SettingsView**

Replace `MyPepTracker/Views/Settings/SettingsView.swift`:

```swift
import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct SettingsView: View {
    @AppStorage("syringeType") private var syringeType = "insulin"
    @AppStorage("overdueDelayHours") private var overdueDelayHours = 2.0
    @AppStorage("expiryWarningDays") private var expiryWarningDays = 3

    @Query(sort: \DoseEntry.timestamp) private var allDoses: [DoseEntry]
    @Query(sort: \Peptide.name) private var allPeptides: [Peptide]
    @Query(sort: \Vial.dateMixed) private var allVials: [Vial]

    @State private var showingExportSheet = false
    @State private var exportURL: URL?

    var body: some View {
        NavigationStack {
            Form {
                Section("Syringe Type") {
                    Picker("Display Units", selection: $syringeType) {
                        Text("Insulin (U-100 / IU)").tag("insulin")
                        Text("Standard (mL)").tag("standard")
                    }
                }

                Section("Notifications") {
                    Stepper(
                        "Overdue alert after \(Int(overdueDelayHours))h",
                        value: $overdueDelayHours,
                        in: 1...12,
                        step: 1
                    )
                    Stepper(
                        "Vial expiry warning: \(expiryWarningDays) days",
                        value: $expiryWarningDays,
                        in: 1...14
                    )
                }

                Section("Data") {
                    Button("Export as JSON") {
                        exportData(format: .json)
                    }
                    Button("Export as CSV") {
                        exportData(format: .csv)
                    }
                }

                Section("Info") {
                    LabeledContent("Peptides", value: "\(allPeptides.count)")
                    LabeledContent("Total Doses Logged", value: "\(allDoses.count)")
                    LabeledContent("Vials Reconstituted", value: "\(allVials.count)")
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExportSheet) {
                if let url = exportURL {
                    ShareLink(item: url)
                }
            }
        }
    }

    private enum ExportFormat { case json, csv }

    private func exportData(format: ExportFormat) {
        let dateFormatter = ISO8601DateFormatter()
        let fileName = "mypeptracker-export-\(dateFormatter.string(from: Date()))"

        var content: String
        var ext: String

        switch format {
        case .json:
            ext = "json"
            let entries = allDoses.map { dose -> [String: Any] in
                var dict: [String: Any] = [
                    "timestamp": dateFormatter.string(from: dose.timestamp),
                    "doseMcg": dose.doseMcg,
                    "unitsInjectedML": dose.unitsInjectedML,
                    "peptide": dose.peptide?.name ?? "Unknown",
                ]
                if let site = dose.injectionSite { dict["injectionSite"] = site.rawValue }
                if let notes = dose.notes { dict["notes"] = notes }
                return dict
            }
            if let data = try? JSONSerialization.data(withJSONObject: entries, options: .prettyPrinted) {
                content = String(data: data, encoding: .utf8) ?? "[]"
            } else {
                content = "[]"
            }

        case .csv:
            ext = "csv"
            var lines = ["timestamp,peptide,doseMcg,unitsInjectedML,injectionSite,notes"]
            for dose in allDoses {
                let site = dose.injectionSite?.rawValue ?? ""
                let notes = dose.notes?.replacingOccurrences(of: ",", with: ";") ?? ""
                lines.append("\(dateFormatter.string(from: dose.timestamp)),\(dose.peptide?.name ?? "Unknown"),\(dose.doseMcg),\(dose.unitsInjectedML),\(site),\(notes)")
            }
            content = lines.joined(separator: "\n")
        }

        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(fileName).\(ext)")
        try? content.write(to: tempURL, atomically: true, encoding: .utf8)
        exportURL = tempURL
        showingExportSheet = true
    }
}
```

- [ ] **Step 2: Build and verify**

```bash
xcodebuild build -project MyPepTracker.xcodeproj -scheme MyPepTracker -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
```

Expected: `** BUILD SUCCEEDED **`

- [ ] **Step 3: Commit**

```bash
git add .
git commit -m "feat: add Settings tab with syringe type, notification prefs, and data export"
```

---

### Task 10: Notification Permission and App Lifecycle

**Files:**
- Modify: `MyPepTracker/MyPepTrackerApp.swift`

- [ ] **Step 1: Update app entry point for notification setup**

Replace `MyPepTracker/MyPepTrackerApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct MyPepTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .task {
                    await setupNotifications()
                }
        }
        .modelContainer(for: [Peptide.self, Vial.self, DoseEntry.self])
    }

    private func setupNotifications() async {
        let manager = NotificationManager.shared
        let granted = await manager.requestPermission()
        if granted {
            manager.registerCategories()
        }
    }
}
```

- [ ] **Step 2: Build and run all tests**

```bash
xcodebuild test -project MyPepTracker.xcodeproj -scheme MyPepTracker -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | grep -E "(Test Suite|Passed|Failed)"
```

Expected: All tests pass, build succeeds.

- [ ] **Step 3: Commit**

```bash
git add .
git commit -m "feat: add notification permission request and category registration on app launch"
```

---

### Task 11: Launch in Simulator and Smoke Test

- [ ] **Step 1: Build and launch in simulator**

```bash
xcodebuild build -project MyPepTracker.xcodeproj -scheme MyPepTracker -destination 'platform=iOS Simulator,name=iPhone 16' 2>&1 | tail -5
xcrun simctl boot "iPhone 16" 2>/dev/null || true
xcrun simctl install "iPhone 16" $(find ~/Library/Developer/Xcode/DerivedData -name "MyPepTracker.app" -path "*/Debug-iphonesimulator/*" | head -1)
xcrun simctl launch "iPhone 16" com.greg.roy.MyPepTracker
```

- [ ] **Step 2: Manual smoke test checklist**

Verify in the simulator:
1. App launches to Today tab with empty state message
2. Navigate to Peptides tab → tap "+" → see preset library
3. Select BPC-157 preset → fields pre-fill → save
4. Go back to Peptides tab → tap BPC-157 → "Reconstitute New Vial" → enter 5mg/2mL → save
5. Navigate to Today tab → see BPC-157 card with vial info
6. Tap "Log Dose" → confirm dose → save
7. Navigate to History tab → see the dose entry
8. Navigate to Settings tab → verify all controls render

- [ ] **Step 3: Final commit**

```bash
git add .
git commit -m "chore: smoke test passed — MyPepTracker v1 feature complete"
```
