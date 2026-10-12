import SwiftUI
import CoreText
import UIKit

enum AppFont {
    /// Register Inter-Bold at launch (belt-and-suspenders with UIAppFonts).
    static func register() {
        guard let url = Bundle.main.url(forResource: "Inter-Bold", withExtension: "ttf") else {
            return
        }
        CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
    }

    /// Figma: Inter Bold. Falls back to system heavy if the custom font is missing.
    static func interBold(_ size: CGFloat) -> Font {
        if UIFont(name: "Inter-Bold", size: size) != nil {
            return .custom("Inter-Bold", size: size)
        }
        // Heavier than .bold so UI never looks thin if Inter fails to load.
        return .system(size: size, weight: .heavy)
    }
}
