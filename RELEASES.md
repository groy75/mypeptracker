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

## Next submission will be

- Marketing: **1.3.0** (next set of user-visible features — TBD).
- Build: **4**.
