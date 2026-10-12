import SwiftUI

enum AppFont {
    /// Figma: Inter (Bold) for all auth/onboarding copy.
    static func interBold(_ size: CGFloat) -> Font {
        .custom("Inter-Bold", size: size)
    }
}
