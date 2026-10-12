import SwiftUI

/// Full-bleed runner photo. Image asset already includes mood; code adds #273151 @ 69% as in Figma.
struct OnboardingBackgroundView: View {
    var blurred: Bool = false
    /// When true, applies full-screen #273151 @ 69% (welcome / Figma frame 4).
    var applyBrandScrim: Bool = true
    var showTopScrimOnly: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Image("OnboardingBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .blur(radius: blurred ? 16 : 0)

                if applyBrandScrim && !showTopScrimOnly {
                    AppTheme.onboardingTopScrim
                        .opacity(AppTheme.onboardingTopScrimOpacity)
                }

                if showTopScrimOnly {
                    LinearGradient(
                        colors: [
                            AppTheme.onboardingTopScrim.opacity(AppTheme.onboardingTopScrimOpacity),
                            AppTheme.onboardingTopScrim.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: max(120, geo.size.height * 0.22))
                    .allowsHitTesting(false)
                }

                if blurred {
                    Color.black.opacity(0.25)
                }
            }
        }
        .ignoresSafeArea()
    }
}
