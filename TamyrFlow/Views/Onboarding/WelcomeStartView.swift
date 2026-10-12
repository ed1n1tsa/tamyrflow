import SwiftUI

/// Figma iPhone 17 — welcome: logo + brand + «НАЧАТЬ».
/// Resting: white pill. Pressed («горит»): blue pill with white label.
struct WelcomeStartView: View {
    var onStart: () -> Void

    var body: some View {
        ZStack {
            OnboardingBackgroundView(
                blurred: false,
                overlayOpacity: 0.35,
                showTopScrim: true
            )

            VStack(spacing: 22) {
                Spacer()

                Image("BrandLogoTF")
                    .resizable()
                    .renderingMode(.template)
                    .scaledToFit()
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 2)
                    .accessibilityLabel("Tamyr Flow")

                Text("TAMYR FLOW")
                    .font(.system(size: 34, weight: .bold))
                    .tracking(2.0)
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.35), radius: 8, y: 2)

                Button(action: onStart) {
                    Text("НАЧАТЬ")
                        .font(.system(size: 17, weight: .bold))
                        .tracking(1.2)
                        .frame(maxWidth: 260)
                        .frame(height: 54)
                }
                .buttonStyle(WelcomeStartButtonStyle())

                Spacer()
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
                color: (configuration.isPressed ? AppTheme.brandBlue : Color.black).opacity(0.35),
                radius: configuration.isPressed ? 16 : 8,
                y: 4
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    WelcomeStartView(onStart: {})
}
