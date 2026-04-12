import Testing
import Foundation
@testable import MyPepTracker

struct NotificationManagerTests {
    @Test func doseReminderIdentifier() {
        let id = NotificationManager.doseReminderID(peptideName: "BPC-157")
        #expect(id == "dose-reminder-BPC-157")
    }

    @Test func overdueIdentifier() {
        let id = NotificationManager.overdueReminderID(peptideName: "BPC-157")
        #expect(id == "overdue-BPC-157")
    }

    @Test func vialExpiryIdentifier() {
        let id = NotificationManager.vialExpiryID(peptideName: "BPC-157")
        #expect(id == "vial-expiry-BPC-157")
    }

    @Test func vialLowIdentifier() {
        let id = NotificationManager.vialLowID(peptideName: "BPC-157")
        #expect(id == "vial-low-BPC-157")
    }

    @Test func nextDoseDateForAfterDoseSchedule() {
        let lastDose = Date(timeIntervalSince1970: 1_700_000_000)
        let next = NotificationManager.nextDoseDate(
            scheduleType: .afterDose,
            frequencyHours: 48,
            lastDoseTimestamp: lastDose,
            scheduledTime: nil,
            scheduleDays: nil
        )
        let expected = lastDose.addingTimeInterval(48 * 3600)
        #expect(next == expected)
    }

    @Test func nextDoseDateReturnsNilForAfterDoseWithNoHistory() {
        let next = NotificationManager.nextDoseDate(
            scheduleType: .afterDose,
            frequencyHours: 48,
            lastDoseTimestamp: nil,
            scheduledTime: nil,
            scheduleDays: nil
        )
        #expect(next == nil)
    }
}
