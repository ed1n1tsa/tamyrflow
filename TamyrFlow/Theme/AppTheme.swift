import SwiftUI

enum AppTheme {
    static let accent = Color(red: 0.35, green: 0.88, blue: 0.82)
    static let accentSecondary = Color(red: 0.45, green: 0.55, blue: 0.98)
    static let danger = Color(red: 1.0, green: 0.38, blue: 0.42)
    static let warning = Color(red: 1.0, green: 0.76, blue: 0.28)

    static let cardBackground = Color.white.opacity(0.08)
    static let cardBorder = Color.white.opacity(0.12)

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
