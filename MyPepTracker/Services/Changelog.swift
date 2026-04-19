import Foundation

enum Changelog {
    /// User-facing release notes. Update this in lockstep with `RELEASES.md`
    /// whenever bumping `CURRENT_PROJECT_VERSION` / `MARKETING_VERSION`.
    /// Newest entry first.
    static let entries: [ChangelogEntry] = [
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
