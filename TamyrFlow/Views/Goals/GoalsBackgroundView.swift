import SwiftUI

struct GoalsBackgroundView: View {
    var body: some View {
        GeometryReader { geo in
            Image("GoalsBackground")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }
}
