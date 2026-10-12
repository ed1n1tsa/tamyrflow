import SwiftUI

/// Dark profile / profile-setup chrome from Figma.
enum ProfileTheme {
    static let page = Color(red: 0 / 255, green: 21 / 255, blue: 47 / 255) // #00152F
    static let cardBorder = Color(red: 18 / 255, green: 68 / 255, blue: 119 / 255) // #124477
    static let cardFill = Color(red: 8 / 255, green: 32 / 255, blue: 64 / 255).opacity(0.72)
    static let accent = Color(red: 47 / 255, green: 107 / 255, blue: 255 / 255) // bright blue
    static let accentSoft = Color(red: 120 / 255, green: 160 / 255, blue: 220 / 255)
    static let muted = Color(red: 140 / 255, green: 170 / 255, blue: 210 / 255).opacity(0.85)
    static let rowDivider = Color.white.opacity(0.08)
    static let dangerFill = Color(red: 0.35, green: 0.08, blue: 0.12).opacity(0.85)
    static let dangerBorder = Color(red: 0.85, green: 0.25, blue: 0.32)
    static let connected = Color(red: 0.25, green: 0.85, blue: 0.45)

    static let cardRadius: CGFloat = 16
    static let contentInset: CGFloat = 19
    static let tabBarHeight: CGFloat = 58
}
