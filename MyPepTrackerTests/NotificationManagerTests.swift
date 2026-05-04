import Testing
import Foundation
@testable import MyPepTracker

@Suite("NotificationManager")
struct NotificationManagerTests {

    // MARK: - Identifier formatting

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

    // MARK: - .afterDose scheduling

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

    // MARK: - .fixedRecurring weekday scheduling

    @Test func nextDoseDateForFixedRecurringWithWeekdays() {
        // Monday 2024-01-01 10:00, schedule for Mon/Wed/Fri at 08:00
        let calendar = Calendar.current
        var components = DateComponents(year: 2024, month: 1, day: 1, hour: 10, minute: 0)
        let now = calendar.date(from: components)!
        setFixedDate(now)
        defer { DateProviderRegistry.reset() }

        var timeComponents = DateComponents(hour: 8, minute: 0)
        let scheduledTime = calendar.date(from: timeComponents)!

        let next = NotificationManager.nextDoseDate(
            scheduleType: .fixedRecurring,
            frequency: .daily,
            lastDoseTimestamp: nil,
            scheduledTime: scheduledTime,
            scheduleDays: [2, 4, 6] // Mon, Wed, Fri
        )

        // Next Monday is Jan 8 (Mon=2), but Jan 1 IS Monday and 10:00 > 08:00,
        // so it should find Wednesday Jan 3 at 08:00
        let expected = calendar.date(from: DateComponents(year: 2024, month: 1, day: 3, hour: 8, minute: 0))!
        #expect(next == expected)
    }

    @Test func nextDoseDateForFixedRecurringTodayIfTimeNotPassed() {
        let calendar = Calendar.current
        var components = DateComponents(year: 2024, month: 1, day: 1, hour: 6, minute: 0)
        let now = calendar.date(from: components)!
        setFixedDate(now)
        defer { DateProviderRegistry.reset() }

        var timeComponents = DateComponents(hour: 8, minute: 0)
        let scheduledTime = calendar.date(from: timeComponents)!

        let next = NotificationManager.nextDoseDate(
            scheduleType: .fixedRecurring,
            frequency: .daily,
            lastDoseTimestamp: nil,
            scheduledTime: scheduledTime,
            scheduleDays: [2] // Monday only
        )

        let expected = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 8, minute: 0))!
        #expect(next == expected)
    }

    @Test func nextDoseDateForFixedRecurringWithLastDoseAndTimeAlignment() {
        let calendar = Calendar.current
        let now = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 12, minute: 0))!
        setFixedDate(now)
        defer { DateProviderRegistry.reset() }

        let lastDose = calendar.date(from: DateComponents(year: 2024, month: 1, day: 9, hour: 9, minute: 0))!
        let scheduledTime = calendar.date(from: DateComponents(hour: 8, minute: 0))!

        let next = NotificationManager.nextDoseDate(
            scheduleType: .fixedRecurring,
            frequency: .daily,
            lastDoseTimestamp: lastDose,
            scheduledTime: scheduledTime,
            scheduleDays: nil
        )

        // Last dose Jan 9 + 1 day = Jan 10 at 09:00, aligned to 08:00.
        // But 08:00 on Jan 10 is in the past (now is 12:00), so returns nil.
        #expect(next == nil)
    }

    @Test func nextDoseDateForFixedRecurringWithoutWeekdaysOrLastDose() {
        let calendar = Calendar.current
        let now = calendar.date(from: DateComponents(year: 2024, month: 1, day: 1, hour: 14, minute: 0))!
        setFixedDate(now)
        defer { DateProviderRegistry.reset() }

        let scheduledTime = calendar.date(from: DateComponents(hour: 8, minute: 0))!

        let next = NotificationManager.nextDoseDate(
            scheduleType: .fixedRecurring,
            frequency: .daily,
            lastDoseTimestamp: nil,
            scheduledTime: scheduledTime,
            scheduleDays: nil
        )

        // Today at 08:00 has passed, so tomorrow Jan 2 at 08:00
        let expected = calendar.date(from: DateComponents(year: 2024, month: 1, day: 2, hour: 8, minute: 0))!
        #expect(next == expected)
    }

    @Test func nextDoseDateReturnsNilWhenNoScheduledTimeAndNoLastDose() {
        let next = NotificationManager.nextDoseDate(
            scheduleType: .fixedRecurring,
            frequency: .daily,
            lastDoseTimestamp: nil,
            scheduledTime: nil,
            scheduleDays: nil
        )
        #expect(next == nil)
    }

    @Test func nextDoseDateForFixedRecurringPastAlignedTimeReturnsNil() {
        let calendar = Calendar.current
        let now = calendar.date(from: DateComponents(year: 2024, month: 1, day: 10, hour: 12, minute: 0))!
        setFixedDate(now)
        defer { DateProviderRegistry.reset() }

        let lastDose = calendar.date(from: DateComponents(year: 2024, month: 1, day: 9, hour: 9, minute: 0))!
        let scheduledTime = calendar.date(from: DateComponents(hour: 8, minute: 0))!

        let next = NotificationManager.nextDoseDate(
            scheduleType: .fixedRecurring,
            frequency: .daily,
            lastDoseTimestamp: lastDose,
            scheduledTime: scheduledTime,
            scheduleDays: nil
        )

        // Jan 9 + 1 day = Jan 10 at 08:00, but now is 12:00 so it's in the past
        #expect(next == nil)
    }
}
