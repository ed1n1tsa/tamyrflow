import SwiftUI

/// Blocks interaction while a measurement / sync is in progress so the user sees clear feedback.
struct MeasurementHUDView: View {
    let state: MeasurementHUDState
    var onDismiss: () -> Void

    @State private var shimmerPhase: CGFloat = 0
    @State private var pulse = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.72)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { onDismiss() }

            // Card visuals don’t steal taps meant for dimmed background / close control.
            cardContent
                .allowsHitTesting(false)

            // Close control above everything (SwiftUI hit-testing + possible SDK main-thread stalls).
            VStack {
                HStack {
                    Spacer(minLength: 0)
                    closeButton
                }
                Spacer(minLength: 0)
            }
            .padding(.top, 12)
            .padding(.trailing, 20)
            .ignoresSafeArea(edges: .top)
            .zIndex(10)
        }
        .onAppear {
            if state.kind == .heart {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            }
            withAnimation(.linear(duration: 1.2).repeatForever(autoreverses: false)) {
                shimmerPhase = 1
            }
        }
    }

    private var cardContent: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.15), lineWidth: 10)
                    .frame(width: 120, height: 120)

                if let p = state.progress01 {
                    Circle()
                        .trim(from: 0, to: CGFloat(min(1, max(0.04, p))))
                        .stroke(
                            AngularGradient(
                                colors: [AppTheme.accent, AppTheme.accentSecondary],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 10, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 120, height: 120)
                } else {
                    ProgressView()
                        .scaleEffect(1.35)
                        .tint(AppTheme.accent)
                }

                Image(systemName: state.kind.systemImage)
                    .font(.title)
                    .foregroundStyle(.white)
                    .scaleEffect(pulseScale)
            }

            Text(L10n.Measure.title(state.kind))
                .font(.title3.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            Text(L10n.Measure.hint)
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            progressBar
        }
        .padding(.vertical, 36)
        .padding(.horizontal, 24)
        .background {
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white.opacity(0.08))
                .overlay {
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                }
        }
        .padding(.horizontal, 24)
    }

    private var closeButton: some View {
        Button(action: onDismiss) {
            Image(systemName: "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
                .background {
                    Circle()
                        .fill(Color.white.opacity(0.18))
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.28), lineWidth: 1)
                        }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.Measure.close)
    }

    private var pulseScale: CGFloat {
        guard state.kind == .heart, pulse else { return 1 }
        return 1.12
    }

    private var progressBar: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.white.opacity(0.12))
                if let p = state.progress01 {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accent, AppTheme.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8, geo.size.width * CGFloat(min(1, max(0, p)))))
                } else {
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [AppTheme.accent.opacity(0.2), AppTheme.accent, AppTheme.accentSecondary.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.38)
                        .offset(x: (geo.size.width * 0.62) * shimmerPhase - geo.size.width * 0.18)
                }
            }
            .clipShape(Capsule())
        }
        .frame(height: 10)
        .padding(.horizontal, 8)
    }
}
