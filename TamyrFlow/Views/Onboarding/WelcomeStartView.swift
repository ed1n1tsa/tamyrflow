import SwiftUI

/// Exact Figma welcome: logo top 26×29, title + НАЧАТЬ centered block.
struct WelcomeStartView: View {
    var onStart: () -> Void

    var body: some View {
        ZStack {
            OnboardingBackgroundView(blurred: false)

            VStack(spacing: 0) {
                // Logo — top center (under status bar), as green mark on Zen screenshot
                BrandLogoMark()
                    .padding(.top, 18)

                Spacer(minLength: 0)

                // Center cluster: title + button (Figma frame)
                VStack(spacing: 28) {
                    Text("TAMYR FLOW")
                        .font(AppFont.interBold(34))
                        .tracking(2.0)
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)

                    Button(action: onStart) {
                        Text("НАЧАТЬ")
                            .font(AppFont.interBold(17))
                            .tracking(1.2)
                            .frame(maxWidth: 280)
                            .frame(height: 54)
                    }
                    .buttonStyle(WelcomeStartButtonStyle())
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 40)
            .padding(.bottom, 24)
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
            .shadow(color: .black.opacity(0.25), radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview {
    WelcomeStartView(onStart: {})
}
