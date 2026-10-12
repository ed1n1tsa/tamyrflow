import SwiftUI

/// Figma iPhone 17 welcome (frame 4): logo above title, НАЧАТЬ lower.
/// Resting: white pill. Pressed: blue pill.
struct WelcomeStartView: View {
    var onStart: () -> Void

    var body: some View {
        ZStack {
            // Background asset (Figma photo 2) already includes #273151 mood; don't double-tint.
            OnboardingBackgroundView(blurred: false, applyBrandScrim: false)

            VStack(spacing: 0) {
                Spacer(minLength: 0)
                    .frame(maxHeight: .infinity)

                // Brand block — upper-middle (logo then title), as on device/Figma ref
                VStack(spacing: 14) {
                    BrandLogoMark(size: 52)

                    Text("TAMYR FLOW")
                        .font(.system(size: 32, weight: .bold))
                        .tracking(1.8)
                        .foregroundStyle(.white)
                }
                .shadow(color: .black.opacity(0.28), radius: 6, y: 2)

                Spacer(minLength: 0)
                    .frame(maxHeight: .infinity)

                Button(action: onStart) {
                    Text("НАЧАТЬ")
                        .font(.system(size: 17, weight: .bold))
                        .tracking(1.2)
                        .frame(maxWidth: 280)
                        .frame(height: 54)
                }
                .buttonStyle(WelcomeStartButtonStyle())
                .padding(.bottom, 64)
            }
            .padding(.horizontal, 40)
        }
    }
}

private struct WelcomeStartButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? Color.white : Color.black)
            .background(
                Capsule(style: .continuous)
                    .fill(configuration.isPressed ? AppTheme.brandBlue : Color.white)
            )
            .shadow(
                color: Color.black.opacity(configuration.isPressed ? 0.2 : 0.28),
                radius: configuration.isPressed ? 10 : 8,
                y: 4
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    WelcomeStartView(onStart: {})
}
