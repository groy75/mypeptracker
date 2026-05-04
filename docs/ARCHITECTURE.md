# MyPepTracker Architecture

## Data Model

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              SwiftData Schema                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐             │
│  │   Peptide    │ 1───>*│    Vial      │      │  DoseEntry   │             │
│  ├──────────────┤       ├──────────────┤      ├──────────────┤             │
│  │ name         │       │ peptideAmountMg     │ timestamp    │             │
│  │ notificationID (UUID)│ waterVolumeML      │ doseMcg      │             │
│  │ defaultDoseMcg      │ dateMixed          │ unitsInjectedML│             │
│  │ scheduleType        │ expiryDays         │ injectionSite│             │
│  │ frequency           │ isActive           │ notes        │             │
│  │ scheduledTime       │ spoiledAt          │              │             │
│  │ scheduleDays        │ totalVolumeUsedML  │              │             │
│  │ notes               │                    │              │             │
│  │ isActive            │                    │              │             │
│  │ cycleStartDate      │                    │              │             │
│  │ cycleLengthWeeks    │                    │              │             │
│  │ cycleNotes          │                    │              │             │
│  └──────────────┘      └──────────────┘      └──────────────┘             │
│         │ 1                        │                      │               │
│         │                          │                      │               │
│         │ 1                        │                      │               │
│         └──────────────────────────┴──────────────────────┘               │
│                         (cascade delete)                                    │
│                                                                             │
│  ┌──────────────────┐      ┌──────────────────┐                           │
│  │ BodyMeasurement  │      │  BodyMetricGoal  │                           │
│  ├──────────────────┤      ├──────────────────┤                           │
│  │ metric (enum)    │      │ metric (enum)    │                           │
│  │ value (SI)       │      │ startValue       │                           │
│  │ timestamp        │      │ startDate        │                           │
│  │ notes            │      │ targetValue      │                           │
│  └──────────────────┘      │ targetDate       │                           │
│                             └──────────────────┘                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Cascade Rules

| Parent | Child | Delete Rule |
|--------|-------|-------------|
| `Peptide` | `Vial` | `.cascade` — deleting a peptide deletes all its vials |
| `Peptide` | `DoseEntry` | `.cascade` — deleting a peptide deletes all its dose history |
| `Vial` | `DoseEntry` | `.cascade` — deleting a vial deletes its dose entries |

### Key Design Decisions

1. **`notificationID: UUID`** — Stable identifier for `UNUserNotificationCenter` requests. Must NOT be derived from user-editable `name` (renaming would orphan pending notifications).

2. **`doseMcg` preserved on each `DoseEntry`** — This is the ground truth. `unitsInjectedML` is derived from concentration at log time. If the user later edits a vial's reconstitution, `doseMcg` stays correct while `unitsInjectedML` is recomputed.

3. **`totalVolumeUsedML` on `Vial`** — Denormalized for quick remaining-doses calculation. Rolled back on dose deletion.

4. **SI storage, display conversion** — All body measurements stored in kg/cm/%. `BodyMetricFormat` handles imperial conversion at presentation layer only.

---

## App Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              App Launch                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  MyPepTrackerApp.swift                                                      │
│  ├── ModelContainer setup (SwiftData + CloudKit .automatic)                │
│  ├── #if DEBUG: screenshot mode → in-memory + DemoSeed                     │
│  ├── Notification permission request                                        │
│  └── Notification ID migration (v1.4.0: peptide-name → UUID)              │
│                                                                             │
│  ContentView.swift                                                          │
│  ├── TabView: Today | Peptides | History | Body | Settings                 │
│  ├── Toast overlay (AppState)                                               │
│  └── What's New sheet (on upgrade)                                          │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Dose Logging Flow

```
User taps "Log Dose" on PeptideCardView
    ↓
LogDoseSheet (modal)
    ├── DoseStepperView + Slider → doseMcg
    ├── Live volume/IU calculation (ConcentrationCalculator)
    ├── DatePicker + InjectionSite picker + Notes
    └── User taps "Log"
        ↓
DoseLoggingService.logDose()
    ├── Calculate volumeML from concentration
    ├── Create DoseEntry
    ├── Update vial.totalVolumeUsedML
    ├── Schedule notifications (dose + overdue + low vial)
    ├── Haptic feedback
    └── Return confirmation message
        ↓
AppState.showToast() → dismiss sheet
```

### Reconstitution Flow

```
User taps "Reconstitute New Vial" on PeptideDetailView
    ↓
ReconstitutionSheet (modal)
    ├── Peptide amount (mg) + BAC water volume (mL)
    ├── Optional guide calculator:
    │   └── Enter desired doseMcg + number of doses
    │       → Computes recommended water volume
    ├── Warning banner if values still at defaults
    └── User taps "Save"
        ↓
Upsert Vial
    ├── If editing existing: recompute all dose unitsInjectedML
    ├── Schedule vial expiry notification
    └── Dismiss sheet
```

---

## Notification System

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Notification Types                                   │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  Type              │ ID Format                    │ Trigger                 │
│  ──────────────────┼──────────────────────────────┼─────────────────────────│
│  Dose Reminder     │ dose-reminder-{uuid}         │ nextDoseDate()          │
│  Overdue Reminder  │ overdue-{uuid}               │ nextDoseDate() + 2h     │
│  Vial Expiry       │ vial-expiry-{uuid}           │ expiryDate - 3 days     │
│  Vial Low          │ vial-low-{uuid}              │ Immediate (≤2 doses)    │
│                                                                             │
│  Action: "Log Dose" on dose-reminder → opens app to Today tab               │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Scheduling Logic (`NotificationManager.nextDoseDate`)

```
scheduleType: .afterDose
    └── lastDose + frequency.hours

scheduleType: .fixedRecurring
    ├── Has scheduleDays (e.g. Mon/Wed/Fri):
    │   └── Find next matching day + scheduledTime
    ├── No scheduleDays, has lastDose:
    │   └── lastDose + frequency, aligned to scheduledTime
    └── No lastDose, has scheduledTime:
        └── Today at scheduledTime (or tomorrow if passed)
```

---

## Services

| Service | Responsibility | Testable? |
|---------|---------------|-----------|
| `ConcentrationCalculator` | Pure math: concentration, volume-for-dose, IU | ✅ Fully (parameterized) |
| `NotificationManager` | UNUserNotificationCenter scheduling | ⚠️ `nextDoseDate()` is; actual scheduling needs mock |
| `DoseLoggingService` | Complete dose-log workflow | ⚠️ Needs mock NotificationManager |
| `ExportService` | JSON/CSV export to temp file | ✅ Pure |
| `ImportService` | JSON/CSV import with peptide creation | ✅ With in-memory context |
| `HealthKitService` | Write body metrics to Apple Health | ❌ Needs device/simulator |
| `WidgetSyncService` | Write next-dose data to shared UserDefaults | ⚠️ Needs App Group setup |
| `DateProvider` | Abstract `Date()` for testing | ✅ Yes |

---

## View Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              View Layer                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  ContentView (TabView root)                                                 │
│  ├── TodayView                                                              │
│  │   └── PeptideCardView (vial gauge + log button)                         │
│  │       └── LogDoseSheet → DoseLoggingService                              │
│  ├── PeptideListView                                                        │
│  │   ├── AddPeptideView → PeptidePreset.loadAll()                          │
│  │   └── PeptideDetailView                                                  │
│  │       ├── ReconstitutionSheet → Vial upsert                             │
│  │       └── LogDoseSheet                                                   │
│  ├── HistoryView                                                            │
│  │   ├── DoseEntryRow (reusable)                                            │
│  │   └── BodyMapView (AthleticSilhouette overlay)                          │
│  ├── BodyView                                                               │
│  │   └── BodySilhouetteView (tappable markers)                             │
│  │       └── MetricDetailView                                               │
│  │           ├── Chart (Swift Charts + rolling mean)                       │
│  │           ├── SetGoalSheet                                               │
│  │           └── LogMeasurementView → HealthKitService                      │
│  └── SettingsView                                                           │
│       ├── ExportService                                                     │
│       └── ImportService                                                     │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Complex Views Requiring Attention

| View | Lines | Complexity |
|------|-------|------------|
| `ReconstitutionSheet` | 340 | 🔴 Guide calculator + model mutation + save logic |
| `MetricDetailView` | 298 | 🔴 Chart + rolling mean + goal card + history |
| `PeptideDetailView` | 249 | 🔴 8 sections, 3 sheets, 3 confirmation dialogs |
| `SetGoalSheet` | 181 | 🟡 Complex init with formatter closure |
| `AddPeptideView` | 150 | 🟡 Preset loading + force unwrap on scheduledTime |

---

## External Dependencies

| Framework | Usage |
|-----------|-------|
| SwiftUI | All UI |
| SwiftData | Persistence + CloudKit sync |
| Swift Charts | MetricDetailView history charts |
| HealthKit | Body metric write-through |
| WidgetKit | Home Screen widget |
| UserNotifications | Dose reminders |
| UniformTypeIdentifiers | File import picker |
| UIKit | Haptics (UINotificationFeedbackGenerator) |

---

## Build System

```
project.yml ──xcodegen──► MyPepTracker.xcodeproj
    │
    ├── MARKETING_VERSION (user-visible, e.g. "1.12.0")
    └── CURRENT_PROJECT_VERSION (build number, ASC-strict)
```

**Never hand-edit `project.pbxproj`.** Always edit `project.yml`, then `xcodegen generate`.

---

## Adding a New Feature

1. **Model changes** → Add to `Schema` in `MyPepTrackerApp.swift`
2. **Business logic** → Add to `Services/` (not views)
3. **UI** → Add to `Views/<Tab>/`
4. **Tests** → Add to `MyPepTrackerTests/` with `@Suite` tag
5. **Bump version** → `project.yml` → `xcodegen generate` → commit → tag
