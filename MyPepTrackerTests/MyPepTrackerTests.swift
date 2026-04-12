import Testing
@testable import MyPepTracker

struct MyPepTrackerTests {
    @Test func appThemeColorsExist() {
        // Verify theme constants are accessible
        _ = AppTheme.primary
        _ = AppTheme.background
        _ = AppTheme.cornerRadius
    }
}
