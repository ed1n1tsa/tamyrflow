import SwiftUI

/// Full-bleed photo + full scrim `#273151` @ 69% (Figma welcome).
struct OnboardingBackgroundView: View {
    var blurred: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("OnboardingBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .blur(radius: blurred ? 16 : 0)

                AppTheme.onboardingTopScrim
                    .opacity(AppTheme.onboardingTopScrimOpacity)

                if blurred {
                    Color.black.opacity(0.20)
                }
            }
        }
        .ignoresSafeArea()
    }
}
