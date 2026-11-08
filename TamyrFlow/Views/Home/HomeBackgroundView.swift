import SwiftUI

struct HomeBackgroundView: View {
    /// Keep the aurora under the header, not clipped into the status bar.
    private let verticalShift: CGFloat = 78

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color(red: 0 / 255, green: 5 / 255, blue: 13 / 255)

                Image("HomeBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(
                        width: geo.size.width,
                        height: geo.size.height + verticalShift
                    )
                    .offset(y: verticalShift)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
            .clipped()
        }
        .ignoresSafeArea()
    }
}
