import SwiftUI

/// Figma logo — fixed **26×29 pt**, vector `logo.svg` only.
struct BrandLogoMark: View {
    var body: some View {
        Image("BrandLogoTF")
            .resizable()
            .renderingMode(.template)
            .interpolation(.none)
            .scaledToFit()
            .foregroundStyle(.white)
            .frame(width: 26, height: 29)
            .accessibilityLabel("Tamyr Flow")
    }
}
