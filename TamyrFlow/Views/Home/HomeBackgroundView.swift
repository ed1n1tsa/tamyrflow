import SwiftUI

struct HomeBackgroundView: View {
    /// Push aurora into the header band, below the status bar.
    private let verticalShift: CGFloat = 56
    private let base = Color(red: 0 / 255, green: 5 / 255, blue: 13 / 255)

    var body: some View {
        // Avoid GeometryReader+ignoresSafeArea size bugs that left a black strip
        // under the status bar. Fill the whole screen with navy, then shift art.
        ZStack(alignment: .top) {
            base

            Image("HomeBackground")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .offset(y: verticalShift)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .ignoresSafeArea()
    }
}
