import SwiftUI
import UIKit

enum AppTheme {
    // MARK: - Colors (adaptive light/dark)
    static let background = Color(.systemGroupedBackground)
    static let surface = Color(.secondarySystemGroupedBackground)

    // Brand accents — resolve per UITraitCollection so they adapt in Dark Mode.
    static let primary = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.40, green: 0.65, blue: 1.00, alpha: 1)   // #66A6FF lighter in dark
            : UIColor(red: 0.20, green: 0.45, blue: 0.90, alpha: 1)   // #3373E6 in light
    })
    static let success = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.25, green: 0.82, blue: 0.60, alpha: 1)   // #40D199
            : UIColor(red: 0.05, green: 0.65, blue: 0.45, alpha: 1)   // #0DA673
    })
    static let warning = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.70, blue: 0.25, alpha: 1)   // #FFB340
            : UIColor(red: 0.90, green: 0.55, blue: 0.00, alpha: 1)   // #E68C00
    })
    static let danger = Color(uiColor: UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 1.00, green: 0.42, blue: 0.42, alpha: 1)   // #FF6B6B
            : UIColor(red: 0.88, green: 0.22, blue: 0.22, alpha: 1)   // #E03838
    })
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
