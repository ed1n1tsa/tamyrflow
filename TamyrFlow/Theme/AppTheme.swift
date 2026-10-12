import SwiftUI

enum AppTheme {
    /// Brand blue from Figma onboarding (НАЧАТЬ / ДАЛЕЕ active).
    static let brandBlue = Color(red: 0.204, green: 0.353, blue: 0.800) // #345ACC
    static let brandBlueDeep = Color(red: 0.106, green: 0.204, blue: 0.459) // #1B3475

    static let accent = brandBlue
    static let accentSecondary = Color(red: 0.45, green: 0.55, blue: 0.98)
    static let danger = Color(red: 1.0, green: 0.38, blue: 0.42)
    static let warning = Color(red: 1.0, green: 0.76, blue: 0.28)

    static let cardBackground = Color.white.opacity(0.08)
    static let cardBorder = Color.white.opacity(0.12)

    static let onboardingOverlay = Color(red: 0.07, green: 0.12, blue: 0.28).opacity(0.72)
    /// Figma top photo scrim: #273151 @ 69%
    static let onboardingTopScrim = Color(red: 39 / 255, green: 49 / 255, blue: 81 / 255)
    static let onboardingTopScrimOpacity = 0.69
    static let onboardingButtonDisabled = Color(red: 0.86, green: 0.87, blue: 0.90)
    static let onboardingButtonDisabledText = Color(red: 0.45, green: 0.47, blue: 0.52)

    static var backgroundGradient: LinearGradient {
        LinearGradient(
            colors: [
                Color(red: 0.06, green: 0.07, blue: 0.14),
                Color(red: 0.10, green: 0.12, blue: 0.22),
                Color(red: 0.05, green: 0.08, blue: 0.16)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var meshGlow: RadialGradient {
        RadialGradient(
            colors: [accent.opacity(0.22), .clear],
            center: .topTrailing,
            startRadius: 20,
            endRadius: 280
        )
    }
}
