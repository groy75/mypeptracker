import Foundation
import UserNotifications

final class NotificationManager: @unchecked Sendable {
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
        frequency: DoseFrequency,
        lastDoseTimestamp: Date?,
        scheduledTime: Date?,
        scheduleDays: [Int]?
    ) -> Date? {
        switch scheduleType {
        case .afterDose:
            guard let lastDose = lastDoseTimestamp else { return nil }
            return lastDose.addingTimeInterval(frequency.hours * 3600)

        case .fixedRecurring:
            guard let time = scheduledTime else { return nil }
            let calendar = Calendar.current
            let timeComponents = calendar.dateComponents([.hour, .minute], from: time)

            if let days = scheduleDays, !days.isEmpty {
                let now = Date()
                let sortedDays = days.sorted()

                for dayOffset in 0 ..< 8 {
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
            frequency: peptide.frequency,
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
            frequency: peptide.frequency,
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
