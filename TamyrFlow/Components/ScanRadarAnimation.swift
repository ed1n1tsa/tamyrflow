import SwiftUI

/// Pulsing “radar” rings while BLE scan is active.
struct ScanRadarAnimation: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate

            ZStack {
                ForEach(0..<4, id: \.self) { index in
                    let delay = Double(index) * 0.22
                    let phase = (sin((t + delay) * 2 * .pi / 2.0) + 1) / 2
                    Circle()
                        .stroke(
                            AppTheme.accent.opacity(0.2 + phase * 0.45),
                            lineWidth: 2
                        )
                        .scaleEffect(0.42 + CGFloat(phase) * (0.5 + CGFloat(index) * 0.07))
                        .opacity(0.2 + phase * 0.55)
                }

                let iconPulse = (sin(t * 2 * .pi / 1.4) + 1) / 2
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .font(.system(size: 34, weight: .semibold))
                    .foregroundStyle(AppTheme.accent)
                    .scaleEffect(1.0 + CGFloat(iconPulse) * 0.12)
                    .shadow(color: AppTheme.accent.opacity(0.55), radius: CGFloat(iconPulse * 12))
            }
            .frame(width: 130, height: 130)
        }
    }
}

struct ScanningBanner: View {
    let isActive: Bool

    var body: some View {
        Group {
            if isActive {
                HStack(spacing: 14) {
                    ScanRadarAnimation()
                        .frame(width: 108, height: 108)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.Scan.scanningTitle)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(.white)
                        Text(L10n.Scan.scanningHint)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 0)
                }
                .padding(16)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(AppTheme.cardBackground)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(AppTheme.accent.opacity(0.4), lineWidth: 1)
                        }
                }
                .transition(.asymmetric(
                    insertion: .opacity.combined(with: .move(edge: .top)),
                    removal: .opacity
                ))
            }
        }
        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: isActive)
    }
}
