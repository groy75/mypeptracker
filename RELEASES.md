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

## Next submission will be

- Marketing: **1.5.0** (Phase 2 body-metric goals, or other work).
- Build: **7**.
