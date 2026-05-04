import Foundation

/// Provides the current date. Default implementation returns `Date()`.
/// Inject a fixed-date implementation in tests for deterministic assertions.
protocol DateProvider {
    func now() -> Date
}

struct LiveDateProvider: DateProvider {
    func now() -> Date { Date() }
}

/// Thread-safe shared date provider. Production code uses `LiveDateProvider`;
/// tests can swap this for a fixed-date provider before assertions.
enum DateProviderRegistry {
    private static let lock = NSLock()
    private static var _current: DateProvider = LiveDateProvider()

    static var current: DateProvider {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _current
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            _current = newValue
        }
    }

    /// Convenience accessor — same as `DateProviderRegistry.current.now()`
    static func now() -> Date { current.now() }

    /// Reset to live clock. Call in `@MainActor` `setUp`/`tearDown` to avoid
    /// leaking fixed dates between tests.
    static func reset() {
        current = LiveDateProvider()
    }
}
