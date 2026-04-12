import SwiftUI

enum AppTheme {
    // MARK: - Colors (adaptive light/dark)
    static let background = Color(.systemGroupedBackground)
    static let surface = Color(.secondarySystemGroupedBackground)
    static let primary = Color(red: 0.20, green: 0.45, blue: 0.90)         // #3373E6 - deeper blue
    static let success = Color(red: 0.05, green: 0.65, blue: 0.45)         // #0DA673
    static let warning = Color(red: 0.90, green: 0.55, blue: 0.0)          // #E68C00
    static let danger = Color(red: 0.88, green: 0.22, blue: 0.22)          // #E03838
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)

    // MARK: - Spacing
    static let paddingSmall: CGFloat = 8
    static let paddingMedium: CGFloat = 16
    static let paddingLarge: CGFloat = 24

    // MARK: - Shape
    static let cornerRadius: CGFloat = 12
    static let cardShadowRadius: CGFloat = 4
    static let cardShadowY: CGFloat = 2
}
