import SwiftUI

enum AppTheme {
    // MARK: - Colors
    static let background = Color(red: 0.94, green: 0.97, blue: 1.0)       // #f0f9ff
    static let surface = Color.white
    static let primary = Color(red: 0.23, green: 0.51, blue: 0.96)         // #3b82f6
    static let success = Color(red: 0.06, green: 0.73, blue: 0.51)         // #10b981
    static let warning = Color(red: 0.96, green: 0.62, blue: 0.04)         // #f59e0b
    static let danger = Color(red: 0.94, green: 0.27, blue: 0.27)          // #ef4444
    static let textPrimary = Color(red: 0.12, green: 0.16, blue: 0.21)     // #1e293b
    static let textSecondary = Color(red: 0.39, green: 0.45, blue: 0.55)   // #64748b

    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24

    // MARK: - Shape
    static let cornerRadius: CGFloat = 12
    static let cardShadowRadius: CGFloat = 4
    static let cardShadowY: CGFloat = 2
}
