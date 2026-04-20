import Foundation

enum Changelog {
    /// User-facing release notes. Update this in lockstep with `RELEASES.md`
    /// whenever bumping `CURRENT_PROJECT_VERSION` / `MARKETING_VERSION`.
    /// Newest entry first.
    static let entries: [ChangelogEntry] = [
        ChangelogEntry(
            version: "1.7.1",
            build: 10,
            date: date("2026-04-19"),
            changes: [
                "Larger, more athletic body silhouette with room for each marker to breathe — neck, chest, and back are no longer stacked on top of each other."
            ]
        ),
        ChangelogEntry(
            version: "1.7.0",
            build: 9,
            date: date("2026-04-19"),
            changes: [
                "New Body layout: a human silhouette with tappable markers at each body part. Shows the current value right on the figure.",
                "Toggle between List and Body views from the segmented picker at the top of the Body tab.",
                "Weight and body-fat stay as pills above the silhouette since they don't map to a specific body part."
            ]
        ),
        ChangelogEntry(
            version: "1.6.0",
            build: 8,
            date: date("2026-04-19"),
            changes: [
                "Each body metric now has its own kg/lb or cm/in toggle — weight in lb, waist in cm, whatever you prefer.",
                "Logging is scoped to one metric at a time: open a metric, tap to record. No more picking the wrong metric from a list.",
                "Fresh metrics show a clear \u{201C}Tap to record\u{201D} hint and a prominent \u{201C}Record your current \u{2026}\u{201D} button."
            ]
        ),
        ChangelogEntry(
            version: "1.5.0",
            build: 7,
            date: date("2026-04-19"),
            changes: [
                "Set a goal for any body metric and watch your progress.",
                "The chart shows a dashed line at your target; a progress bar on each row tracks how close you are.",
                "Progress stays honest about overshoot and regression — it won\u{2019}t round up to make you feel better."
            ]
        ),
        ChangelogEntry(
            version: "1.4.1",
            build: 6,
            date: date("2026-04-19"),
            changes: [
                "Fixes a crash when tapping a body metric (e.g. Weight) to see its chart."
            ]
        ),
        ChangelogEntry(
            version: "1.4.0",
            build: 5,
            date: date("2026-04-19"),
            changes: [
                "New Body tab for tracking weight, waist, neck, chest, back width, biceps, thighs, and body-fat %.",
                "Swift Charts line graph of every metric over time, with a 7-day rolling mean on weight so daily fluctuations don\u{2019}t mislead you.",
                "Log measurements in metric or imperial — toggle in Settings.",
                "Fixes a notification-scheduling fragility so renaming a peptide no longer leaves ghost reminders behind."
            ]
        ),
        ChangelogEntry(
            version: "1.3.0",
            build: 4,
            date: date("2026-04-18"),
            changes: [
                "More accurate \u{201C}doses remaining\u{201D} estimate, based on your actual dose history.",
                "New mcg slider in Log Dose with live mL + IU display as you drag.",
                "In-app What\u{2019}s New screen, and a gentle prompt after each update.",
                "Haptic feedback on dose log success and delete confirmations.",
                "Larger Log Dose buttons and polished Dark Mode colors.",
                "Body map now reads clearly with VoiceOver."
            ]
        ),
        ChangelogEntry(
            version: "1.2.0",
            build: 3,
            date: date("2026-04-18"),
            changes: [
                "Delete doses with automatic vial-volume rollback.",
                "Edit a vial's mix date, with a warning if concentration would change.",
                "Dose-logged toast and auto-jump back to Today."
            ]
        ),
        ChangelogEntry(
            version: "1.1.0",
            build: 2,
            date: date("2026-04-18"),
            changes: [
                "Delete peptides with a confirmation that cascades to vials and doses.",
                "Fix notification scheduling edge cases.",
                "Ship the iOS privacy manifest."
            ]
        ),
        ChangelogEntry(
            version: "1.0.0",
            build: 1,
            date: date("2026-04-12"),
            changes: [
                "Initial App Store release.",
                "Track peptides, reconstituted vials, and injection history."
            ]
        )
    ]

    static var latestBuild: Int {
        entries.first?.build ?? 0
    }

    static var currentBuild: Int {
        let raw = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        return Int(raw) ?? 0
    }

    private static func date(_ string: String) -> Date {
        // Parse as the device's local calendar day so the formatted display
        // matches what the user sees — UTC parsing caused an off-by-one west of GMT.
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = .current
        return fmt.date(from: string) ?? Date()
    }
}
