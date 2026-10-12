import SwiftUI

/// Full-bleed runner photo from Figma (iPhone 17 onboarding).
struct OnboardingBackgroundView: View {
    var blurred: Bool = false
    var overlayOpacity: Double = 0.55

    var body: some View {
        GeometryReader { geo in
            Image("OnboardingBackground")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .blur(radius: blurred ? 18 : 0)
                .overlay {
                    AppTheme.onboardingOverlay.opacity(overlayOpacity)
                }
        }
        .ignoresSafeArea()
    }
}
