import SwiftUI

/// Zen logo asset — exactly **26×29 pt**.
struct BrandLogoMark: View {
    var body: some View {
        Image("BrandLogoTF")
            .resizable()
            .renderingMode(.template)
            .interpolation(.none)
            .frame(width: 26, height: 29)
            .foregroundStyle(.white)
            .accessibilityLabel("Tamyr Flow")
    }
}
