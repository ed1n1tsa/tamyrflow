import SwiftUI

/// Combined TF monogram (shared stem) — white mark from Figma logo.
struct BrandLogoMark: View {
    var size: CGFloat = 56

    var body: some View {
        Image("BrandLogoTF")
            .resizable()
            .renderingMode(.template)
            .scaledToFit()
            .foregroundStyle(.white)
            .frame(width: size, height: size * (29.0 / 26.0))
            .accessibilityLabel("Tamyr Flow")
    }
}
