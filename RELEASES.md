# Release Log

Single source of truth for MyPepTracker App Store submissions.

**Bundle ID:** `com.greg.roy.MyPepTracker`
**Team ID:** `7FCS8W78F5`
**ASC App ID / Apple ID (adam):** `6762103081`
**SKU:** `mypeptracker`
**ASC API credentials:** Infisical homelab/prod `/peptide-tracker/` (keys: `ASC_API_KEY_ID`, `ASC_API_ISSUER_ID`, `ASC_API_KEY_P8`, plus `APPLE_ID_EMAIL`, `APP_STORE_*`)

## How versioning works here

- `MARKETING_VERSION` in `project.yml` → what users see in the App Store (e.g. `1.0.0`).
- `CURRENT_PROJECT_VERSION` in `project.yml` → the build number (e.g. `1`). Must be strictly higher than anything ever uploaded to App Store Connect under this bundle ID — even builds that were rejected, expired, or never submitted.
- Bump `CURRENT_PROJECT_VERSION` for every archive you upload.
- Bump `MARKETING_VERSION` for every user-visible release.
- After every successful ASC upload, add a row below and tag the commit: `git tag v<marketing>-b<build>`.

## Pre-archive checklist (follow every time)

1. `git status` clean on `main`.
2. Read the latest row below — confirm next build number is `last + 1`.
3. Update `project.yml` `MARKETING_VERSION` / `CURRENT_PROJECT_VERSION`.
4. `xcodegen generate`.
5. `xcodebuild archive` → upload to App Store Connect.
6. Append a row to the history table below, commit, tag `v<marketing>-b<build>`, push.

## History

| Marketing | Build | Uploaded to ASC | Status        | Notes                                                                                                                                          |
| --------- | ----- | --------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------------------------------- |
| 1.0.0     | 1     | 2026-04-12      | **Live**      | Initial App Store release. Peptide + vial + dose tracking. ASC state: VALID, not expired.                                                      |
| 1.1.0     | 2     | 2026-04-18      | **TestFlight** | Peptide deletion with cascade + confirmation. Notification scheduling bug fixes. Privacy manifest. Delivery UUID `ae1a3cf5-9a5c-4243-80db-d68e54c319d0`.                                     |
| 1.2.0     | 3     | 2026-04-18      | **Live**      | Dose deletion with vial rollback (#2), editable vial `dateMixed` with concentration-change warning (#3), dose-log toast + auto-nav to Today (#1). Delivery UUID `d6032529-e4d4-4614-b9e6-9e0418c854a4`. Submitted 2026-04-18 via ASC API `reviewSubmissions` flow, release type: **automatic after approval**. Apple-approved and auto-released same day. appStoreVersion `76cc0b20-5531-4d77-8d3e-bf301e9ce462`, reviewSubmission `a46d3c82-c9fb-48fa-bc7c-44ea9ff05883`. |
| 1.3.0     | 4     | 2026-04-18      | **Live**      | HIG pass (44pt tap targets, Dark Mode colors, sheet detents, haptics, VoiceOver on body map). Precise remaining-doses calc based on actual dose history. mcg slider in Log Dose with live mL + IU display. In-app What's New screen + first-launch-after-update sheet. Delivery UUID `89eae6e2-e437-43f6-a954-f8e35a686c71`. Submitted 2026-04-19 via ASC API, release type **AFTER_APPROVAL**. 6 new screenshots uploaded to `APP_IPHONE_67` set (1320×2868). appStoreVersion `87e75693-35f3-4884-bb26-4ec6eccb2dd9`, reviewSubmission `0f320c11-f727-42cd-8bd9-db0ac421662a`. Apple-approved and auto-released 2026-04-19. |
| 1.4.0     | 5     | 2026-04-19      | **Superseded** | New Body tab with per-metric logging (weight, waist, neck, chest, back width, bicep L/R, thigh L/R, body fat %), Swift Charts history with 7-day rolling mean on weight, imperial/metric toggle in Settings. Notification IDs migrated from peptide-name to stable UUIDs so renaming no longer leaves ghost reminders. Delivery UUID `572eb290-eda4-44ed-ab0d-7efb94847576`. Superseded by 1.4.1 — tapping a metric crashed the app due to a SwiftData `#Predicate` issue on enum rawValue access. |
| 1.4.1     | 6     | 2026-04-19      | **TestFlight** | Hotfix: tapping a Body metric (e.g. Weight) to see its chart no longer crashes. SwiftData `#Predicate` traversing `.rawValue` on an @Model-stored enum was the cause; switched MetricDetailView to fetch-all + filter-in-memory. Also baked `ITSAppUsesNonExemptEncryption=NO` into Info.plist so future builds skip the Export Compliance prompt. Delivery UUID `8c8db232-50bb-4301-a4b0-60b3a00d65e7`. **TestFlight-only**. |
| 1.5.0     | 7     | 2026-04-19      | **Superseded** | Phase 2 body-metric goals: `BodyMetricGoal` @Model with direction inference + progress calc. New `SetGoalSheet`, goal card + dashed RuleMark on `MetricDetailView`, progress bar on each `BodyView` row. Delivery UUID `f80b0bed-6cd8-4773-a2d9-07558b10d98d`. Superseded by 1.6.0 after dogfooding feedback on logging UX. |
| 1.6.0     | 8     | 2026-04-19      | **TestFlight** | Per-metric kg/lb (cm/in) toggle in each metric detail header — weight in lb + waist in cm is a real user pattern. Logging is scoped per-metric (no more generic sheet with picker); empty state shows "Record your current <metric>" button. `BodyMetricUnitPreference` helper + UserDefaults `unit_<metric>`. Settings global toggle demoted to "default for new metrics" with explanatory footer. Delivery UUID `b80aa1c0-a113-47d8-a1c8-639d9100a9ce`. **TestFlight-only**. |
| 1.7.0     | 9     | 2026-04-19      | **Superseded** | Phase 3 body silhouette: new `BodySilhouetteView` renders a front-facing figure with tappable markers at each anatomy metric's `bodyPosition`. Delivery UUID `73f9a8ad-737f-4b17-9329-6fd1056f98f8`. Superseded by 1.7.1 — silhouette was too small; neck/chest/back markers overlapped. |
| 1.7.1     | 10    | 2026-04-19      | **Superseded** | Bigger athletic silhouette (320x560). Delivery UUID `7797037f-b897-4424-9bed-eb4e1d5d24b1`. Superseded by 1.8.0. |
| 1.8.0     | 11    | 2026-04-19      | **TestFlight** | Silhouette is now the only Body layout — segmented List/Body toggle removed. BodyView is a thin wrapper around BodySilhouetteView; `Layout` enum, `row(for:)`, `latestByMetric`, `sevenDayDelta`, and `@AppStorage("bodyLayout")` all deleted (~112 LoC net). Every metric remains reachable via pills (weight/body-fat) or silhouette markers. Delivery UUID `ea7f8823-d4b5-4fb5-8b24-40c4de2b6990`. **TestFlight-only**. |
| 1.8.1     | 12    | 2026-04-19      | **Waiting for Review** | History's injection-site map now uses the same athletic silhouette as the Body tab. Extracted into reusable `AthleticSilhouette` that scales to container size (Body tab renders 320x560, History renders 240x420). `InjectionSite` gains `silhouettePosition: CGPoint` in the same 320x560 reference space; BodyMapView scales per render. Delivery UUID `e217c8e4-bc81-473d-a360-c6b5f2f2204d`. Submitted 2026-04-19 via ASC API `reviewSubmissions` flow, release type **AFTER_APPROVAL**. 7 iPhone 6.7" screenshots (1320×2868) + 6 iPad Pro 12.9" screenshots (2064×2752). appStoreVersion `6d5de186-dbf6-4270-acec-15a70c02fa59`, reviewSubmission `eeb68952-d6f0-4436-989f-94eb849d40e9`. |

| 1.9.0     | 13    | 2026-04-30      | **Superseded** | New vial form shows an orange warning banner until both peptide amount and water volume are explicitly changed from defaults. Superseded by build 14 (dose-remaining fix). Delivery UUID `3240fbba-2c2d-4acb-b938-492a3f07eb22`. |
| 1.9.0     | 14    | 2026-04-30      | **TestFlight** | Fix: estimated remaining doses now calculated from doseMcg (preserved on each entry) rather than unitsInjectedML, making it immune to concentration edits. Also fixes saveVial() to recompute unitsInjectedML and totalVolumeUsedML for all entries when concentration changes — previously editing a vial's amount/water after logging doses caused totalVolumeUsedML to exceed waterVolumeML, reporting 0 doses remaining. Delivery UUID `22f3d0c7-6919-48e4-9edc-c21fabb430bc`. **TestFlight-only**. |

| 1.10.0    | 15    | 2026-04-30      | **TestFlight** | Spoil Vial: new destructive action in Active Vial section to retire a vial immediately (marks spoiledAt timestamp, sets isActive=false, preserves dose history). Changelog updated with 1.9.0 and 1.10.0 entries — What's New popup was stale at build 12. Delivery UUID `0d3f99f9-da59-49c8-87c2-fcb1bbc4b869`. **TestFlight-only**. |

| 1.11.0    | 16    | 2026-04-30      | **TestFlight** | Doses remaining now based on last logged dose instead of average, so titrating users see an estimate that reflects their current dose level. Vial detail shows "Based on last dose: X mcg" so the basis is always explicit. Delivery UUID `64c0dbac-3d11-4ac4-bcfc-b8fc2132a3f6`. **TestFlight-only**. |

## Next submission will be

- Marketing: **1.12.0** (TBD).
- Build: **17**.
