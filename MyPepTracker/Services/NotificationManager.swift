import Foundation
import UserNotifications
import SwiftData

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

    static func doseReminderID(peptideNotificationID: UUID) -> String {
        "dose-reminder-\(peptideNotificationID.uuidString)"
    }

    static func overdueReminderID(peptideNotificationID: UUID) -> String {
        "overdue-\(peptideNotificationID.uuidString)"
    }

    static func vialExpiryID(peptideNotificationID: UUID) -> String {
        "vial-expiry-\(peptideNotificationID.uuidString)"
    }

    static func vialLowID(peptideNotificationID: UUID) -> String {
        "vial-low-\(peptideNotificationID.uuidString)"
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
            let calendar = Calendar.current
            let now = DateProviderRegistry.now()

            // If specific weekdays are set (e.g., Mon/Wed/Fri), find the next matching day
            if let days = scheduleDays, !days.isEmpty, let time = scheduledTime {
                let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                let sortedDays = days.sorted()

                for dayOffset in 0 ..< 15 {
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
                return nil
            }

            // No specific weekdays — use last dose + frequency interval
            if let lastDose = lastDoseTimestamp {
                let nextFromLastDose = lastDose.addingTimeInterval(frequency.hours * 3600)

                // If a scheduled time is set, align to that time on the target day
                if let time = scheduledTime {
                    let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                    var dayComponents = calendar.dateComponents([.year, .month, .day], from: nextFromLastDose)
                    dayComponents.hour = timeComponents.hour
                    dayComponents.minute = timeComponents.minute
                    if let aligned = calendar.date(from: dayComponents) {
                        return aligned > now ? aligned : nil
                    }
                }

                return nextFromLastDose > now ? nextFromLastDose : nil
            }

            // No last dose — schedule for today at the scheduled time, or now
            if let time = scheduledTime {
                let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
                var components = calendar.dateComponents([.year, .month, .day], from: now)
                components.hour = timeComponents.hour
                components.minute = timeComponents.minute
                if let date = calendar.date(from: components), date > now {
                    return date
                }
                return calendar.date(byAdding: .day, value: 1, to: calendar.date(from: components)!)
            }
            return nil
        }
    }

    // MARK: - Schedule Dose Reminder

    func scheduleDoseReminder(for peptide: Peptide) {
        let id = Self.doseReminderID(peptideNotificationID: peptide.notificationID)
        center.removePendingNotificationRequests(withIdentifiers: [id])
        syncWidget()

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
        let id = Self.overdueReminderID(peptideNotificationID: peptide.notificationID)
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
        let id = Self.vialExpiryID(peptideNotificationID: peptide.notificationID)
        center.removePendingNotificationRequests(withIdentifiers: [id])

        guard let warningDate = Calendar.current.date(byAdding: .day, value: -warningDays, to: vial.expiryDate) else { return }

        guard warningDate > DateProviderRegistry.now() else { return }

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
        let id = Self.vialLowID(peptideNotificationID: peptide.notificationID)
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
            Self.doseReminderID(peptideNotificationID: peptide.notificationID),
            Self.overdueReminderID(peptideNotificationID: peptide.notificationID),
            Self.vialExpiryID(peptideNotificationID: peptide.notificationID),
            Self.vialLowID(peptideNotificationID: peptide.notificationID),
        ]
        center.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - One-time Migration

    /// Wipes every pending notification request and re-schedules dose + overdue
    /// reminders for all active peptides, plus vial-expiry warnings for their
    /// active vials. Called once at launch on v1.4.0 to purge legacy
    /// name-keyed identifiers left over from ≤1.3.0.
    func wipePendingAndReschedule(peptides: [Peptide]) {
        center.removeAllPendingNotificationRequests()
        for peptide in peptides where peptide.isActive {
            scheduleDoseReminder(for: peptide)
            scheduleOverdueReminder(for: peptide)
            if let vial = peptide.activeVial {
                scheduleVialExpiryWarning(for: peptide, vial: vial)
            }
        }
        WidgetSyncService.shared.syncNextDose(peptides: peptides)
    }

    private func syncWidget() {
        Task { @MainActor in
            let context = MyPepTrackerApp.sharedContainer?.mainContext
            guard let context else { return }
            let peptides = (try? context.fetch(FetchDescriptor<Peptide>())) ?? []
            WidgetSyncService.shared.syncNextDose(peptides: peptides)
        }
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
