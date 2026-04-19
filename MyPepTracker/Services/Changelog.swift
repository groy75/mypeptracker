import Foundation

enum Changelog {
    /// User-facing release notes. Update this in lockstep with `RELEASES.md`
    /// whenever bumping `CURRENT_PROJECT_VERSION` / `MARKETING_VERSION`.
    /// Newest entry first.
    static let entries: [ChangelogEntry] = [
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
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd"
        fmt.timeZone = TimeZone(identifier: "UTC")
        return fmt.date(from: string) ?? Date()
    }
}
