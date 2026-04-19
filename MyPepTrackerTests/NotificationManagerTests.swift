import Testing
import Foundation
@testable import MyPepTracker

struct NotificationManagerTests {
    @Test func doseReminderIdentifier() {
        let uuid = UUID()
        let id = NotificationManager.doseReminderID(peptideNotificationID: uuid)
        #expect(id == "dose-reminder-\(uuid.uuidString)")
    }

    @Test func overdueIdentifier() {
        let uuid = UUID()
        let id = NotificationManager.overdueReminderID(peptideNotificationID: uuid)
        #expect(id == "overdue-\(uuid.uuidString)")
    }

    @Test func vialExpiryIdentifier() {
        let uuid = UUID()
        let id = NotificationManager.vialExpiryID(peptideNotificationID: uuid)
        #expect(id == "vial-expiry-\(uuid.uuidString)")
    }

    @Test func vialLowIdentifier() {
        let uuid = UUID()
        let id = NotificationManager.vialLowID(peptideNotificationID: uuid)
        #expect(id == "vial-low-\(uuid.uuidString)")
    }

    @Test func identifiersAreStableForSameUUID() {
        let uuid = UUID()
        #expect(
            NotificationManager.doseReminderID(peptideNotificationID: uuid)
                == NotificationManager.doseReminderID(peptideNotificationID: uuid)
        )
    }

    @Test func identifiersDifferForDifferentUUIDs() {
        let a = NotificationManager.doseReminderID(peptideNotificationID: UUID())
        let b = NotificationManager.doseReminderID(peptideNotificationID: UUID())
        #expect(a != b)
    }

    @Test func nextDoseDateForAfterDoseSchedule() {
        let lastDose = Date(timeIntervalSince1970: 1_700_000_000)
        let next = NotificationManager.nextDoseDate(
            scheduleType: .afterDose,
            frequency: .everyOtherDay,
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
            frequency: .everyOtherDay,
            lastDoseTimestamp: nil,
            scheduledTime: nil,
            scheduleDays: nil
        )
        #expect(next == nil)
    }
}
