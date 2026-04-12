# MyPepTracker — Design Spec

**Date:** 2026-04-12
**Author:** Greg Roy
**Status:** Draft
**Platform:** iOS (iPhone)
**Stack:** SwiftUI + SwiftData + UNUserNotificationCenter
**Target:** iOS 17+, Xcode 26.4, Swift 6.3

## Purpose

MyPepTracker — a personal iPhone app for tracking peptide reconstitution, dosing, and scheduling. Replaces manual tracking with structured logging, auto-calculated concentrations, remaining dose estimates, and push notification reminders.

## Users

Greg — sole user. No multi-user, no account system, no backend.

## Data Model

### Peptide

The top-level entity representing a peptide compound in the user's roster.

| Field | Type | Notes |
|-------|------|-------|
| name | String | e.g., "BPC-157", "Semaglutide" |
| defaultDoseMcg | Double | Default dose in micrograms |
| scheduleType | ScheduleType enum | `.fixedRecurring` or `.afterDose` |
| frequencyHours | Double | Hours between doses (24, 48, 168, etc.) |
| scheduledTime | Date? | Time of day for fixed schedules |
| scheduleDays | [Int]? | Days of week for fixed schedules (1=Mon..7=Sun) |
| notes | String? | General notes about this peptide |
| isActive | Bool | Whether currently in use |
| vials | [Vial] | Relationship: has many Vials |
| doseEntries | [DoseEntry] | Relationship: has many DoseEntries |

### Vial

Represents a single reconstituted vial of a peptide.

| Field | Type | Notes |
|-------|------|-------|
| peptideAmountMg | Double | Peptide amount in the vial (mg) |
| waterVolumeML | Double | BAC water added (mL) |
| concentrationMcgPerUnit | Double | Auto-calculated: (peptideAmountMg × 1000) ÷ waterVolumeML. "Unit" = 1 mL. For insulin syringes (U-100), 1 mL = 100 IU, so the app converts to IU for display when that syringe type is selected. |
| dateMixed | Date | When the vial was reconstituted |
| expiryDays | Int | Days until expiry (default: 30) |
| totalUnitsUsed | Double | Running total of units drawn from this vial |
| isActive | Bool | Whether this is the current vial for the peptide |
| peptide | Peptide | Relationship: belongs to Peptide |
| doseEntries | [DoseEntry] | Relationship: has many DoseEntries |

**Derived properties:**
- `expiryDate`: dateMixed + expiryDays
- `isExpired`: expiryDate < now
- `remainingVolume`: waterVolumeML - totalUnitsUsed
- `estimatedRemainingDoses`: remainingVolume ÷ (peptide.defaultDoseMcg ÷ concentrationMcgPerUnit)

### DoseEntry

A single logged dose.

| Field | Type | Notes |
|-------|------|-------|
| timestamp | Date | When the dose was taken |
| doseMcg | Double | Dose amount in micrograms |
| unitsInjected | Double | Auto-calculated: doseMcg ÷ vial.concentrationMcgPerUnit |
| injectionSite | InjectionSite? | Optional enum: abdomen, thighLeft, thighRight, deltoidLeft, deltoidRight, gluteLeft, gluteRight, other |
| notes | String? | Optional observations |
| peptide | Peptide | Relationship: belongs to Peptide |
| vial | Vial | Relationship: belongs to Vial |

### PeptidePreset (bundled JSON, not SwiftData)

Read-only catalog of common peptides to pre-fill when adding a new one.

| Field | Type | Notes |
|-------|------|-------|
| name | String | Peptide name |
| typicalDoseMcgLow | Double | Low end of typical dose range |
| typicalDoseMcgHigh | Double | High end of typical dose range |
| typicalVialSizeMg | Double | Common vial size |
| commonFrequencyHours | Double | Typical dosing frequency |
| category | String | e.g., "Healing", "GH Secretagogue", "Weight Management" |

### Enums

```swift
enum ScheduleType: String, Codable {
    case fixedRecurring  // dose at specific days/times
    case afterDose       // next dose N hours after last logged dose
}

enum InjectionSite: String, Codable, CaseIterable {
    case abdomen
    case thighLeft, thighRight
    case deltoidLeft, deltoidRight
    case gluteLeft, gluteRight
    case other
}
```

## Navigation

Four-tab layout via TabView:

### Tab 1: Today (default)

The daily dashboard and most-used screen.

- List of active peptides with next dose countdown
- Overdue doses highlighted with warning styling
- Quick "Log Dose" button per peptide — opens a half-sheet
- Active vial status summary (days until expiry, estimated doses remaining)
- Vial warnings (expiring soon, running low) shown inline

### Tab 2: Peptides

Peptide roster management.

- List of all peptides (active section, archived section)
- "+" button to add new peptide (from preset library or custom entry)
- Tap peptide → detail view:
  - Edit schedule settings
  - Active vial info with reconstitution details
  - "New Vial" button to reconstitute
  - Dose history scoped to this peptide

### Tab 3: History

Full dose log across all peptides.

- Chronological timeline (newest first)
- Filter by peptide (segmented control or picker)
- Injection site body map view — simple front-facing body outline with dots showing recent injection sites, color-coded by peptide
- Notes visible inline on each entry
- Tap entry to edit or delete

### Tab 4: Settings

App configuration.

- Default syringe type (insulin U-100, standard mL) — affects unit display
- Notification preferences (enable/disable per type, overdue delay)
- Default vial expiry warning days
- Export data as JSON or CSV

## Key User Flows

### Log a Dose (most frequent action)

1. Open app → Today tab
2. Tap "Log Dose" on a peptide card
3. Half-sheet appears with:
   - Pre-filled dose amount (from peptide default)
   - Editable dose field
   - Injection site picker (optional, defaults to last used)
   - Notes field (optional)
4. Tap "Log" → dose saved
5. Vial's totalUnitsUsed incremented
6. Next notification scheduled based on schedule type

### Reconstitute a Vial

1. Peptides tab → tap peptide → "New Vial"
2. Enter peptide amount (mg) — pre-filled from preset if available
3. Enter BAC water volume (mL)
4. Concentration auto-displayed as you type
5. Save → previous vial marked inactive, new vial is active
6. Expiry countdown begins

### Add a New Peptide

1. Peptides tab → "+" button
2. Option A: pick from preset library (search/browse by category)
3. Option B: enter custom name
4. Set default dose, schedule type, frequency
5. Optionally reconstitute first vial immediately
6. Save → peptide appears on Today tab, notifications scheduled

## Notifications

All notifications are local via UNUserNotificationCenter. No server, no APNs.

### Dose Reminder

- **Fixed schedule:** Pre-scheduled for the configured days and time of day. Recalculated when schedule settings change.
- **After-dose:** Scheduled when a dose is logged. Next reminder = dose timestamp + frequencyHours.
- **Content:** "Time to take your [Peptide Name] ([dose]mcg)"
- **Action:** "Log Dose" button opens app to the dose confirm screen for that peptide.

### Overdue Dose

- Fires 2 hours after a scheduled dose if no DoseEntry was logged in that window.
- Configurable delay in Settings.
- Content: "You missed your [Peptide Name] dose scheduled at [time]"
- Fires once per missed dose.

### Vial Expiring

- Fires N days before vial expiry (default: 3 days, configurable).
- Content: "Your [Peptide Name] vial expires in [N] days — consider reconstituting a new one"

### Vial Running Low

- Fires when estimated remaining doses ≤ 2.
- Checked after each dose log.
- Content: "Your [Peptide Name] vial has approximately [N] doses remaining"

### iOS Limits

- 64 pending local notifications maximum. With 3-5 peptides this is never a constraint.
- Notifications are rescheduled on app launch to stay current.

## Visual Direction

**Clinical Clean** — light, professional, friendly.

- Light background (#f0f9ff family), soft card surfaces with subtle shadows
- Primary: blue (#3b82f6), Success: green (#10b981), Warning: amber (#f59e0b), Text: dark slate (#1e293b)
- System font (SF Pro) for platform consistency
- Rounded cards (12pt radius), generous whitespace
- Status indicators using colored dots/badges
- Supports system dark mode (inverted palette, same color accents)

## Data Storage

- **SwiftData** with local-only ModelContainer
- No iCloud sync in v1 (upgrade path available via CloudKit later)
- Data persists in the app's sandboxed container
- Backed up automatically via iCloud device backup

## Testing Strategy

- Unit tests for concentration calculations, dose scheduling logic, remaining dose estimates
- UI tests for the three key flows (log dose, reconstitute vial, add peptide)
- Notification scheduling verification

## Out of Scope (v1)

- iCloud sync / multi-device
- Apple Watch companion
- HealthKit integration
- Photo attachment on doses
- Sharing/export to healthcare provider
- iPad layout optimization
