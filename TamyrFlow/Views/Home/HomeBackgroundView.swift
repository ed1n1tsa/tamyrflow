import SwiftUI

struct HomeBackgroundView: View {
    var body: some View {
        GeometryReader { geo in
            Image("HomeBackground")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }
}
