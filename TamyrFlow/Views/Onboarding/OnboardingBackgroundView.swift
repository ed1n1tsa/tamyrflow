import SwiftUI

/// Full-bleed runner photo from Figma (iPhone 17 onboarding).
struct OnboardingBackgroundView: View {
    var blurred: Bool = false
    /// Full-screen wash (welcome uses lighter wash + top scrim).
    var overlayOpacity: Double = 0.55
    /// Top darkened container #273151 @ 69% (Figma).
    var showTopScrim: Bool = false

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .top) {
                Image("OnboardingBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .blur(radius: blurred ? 18 : 0)

                if overlayOpacity > 0 {
                    AppTheme.onboardingOverlay.opacity(overlayOpacity)
                }

                if showTopScrim {
                    // Slightly taller than status bar so the photo top reads darkened like Figma.
                    LinearGradient(
                        colors: [
                            AppTheme.onboardingTopScrim.opacity(AppTheme.onboardingTopScrimOpacity),
                            AppTheme.onboardingTopScrim.opacity(AppTheme.onboardingTopScrimOpacity * 0.85),
                            AppTheme.onboardingTopScrim.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: max(140, geo.size.height * 0.28))
                    .allowsHitTesting(false)
                }
            }
        }
        .ignoresSafeArea()
    }
}
