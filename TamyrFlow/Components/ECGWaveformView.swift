import SwiftUI

/// Medical-style ECG strip: grid + live polyline + sweep cursor while measuring.
struct ECGWaveformView: View {
    let samples: [Float]
    var isLive: Bool
    /// Optional bpm from band during test.
    var liveHeartRate: Int?

    private let gridMajor: CGFloat = 24
    private let gridMinor: CGFloat = 6

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(L10n.ECG.waveTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.55))
                Spacer()
                if let hr = liveHeartRate, hr > 0 {
                    Label("\(hr) bpm", systemImage: "heart.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(AppTheme.danger)
                }
            }

            Group {
                if isLive {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                        ecgCanvas(sweepDate: timeline.date)
                    }
                } else {
                    ecgCanvas(sweepDate: nil)
                }
            }

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.45))
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.35))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                }
        }
    }

    private func ecgCanvas(sweepDate: Date?) -> some View {
        Canvas { context, size in
            drawGrid(context: &context, size: size)
            drawWave(context: &context, size: size)
            if let date = sweepDate {
                drawSweep(context: &context, size: size, date: date)
            }
        }
        .frame(height: 160)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var subtitle: String {
        if isLive, samples.isEmpty {
            return L10n.ECG.waveWaiting
        }
        if isLive {
            return L10n.ECG.waveSubLive
        }
        if samples.isEmpty {
            return L10n.ECG.waveSubIdle
        }
        return L10n.ECG.waveFrozen
    }

    private func drawGrid(context: inout GraphicsContext, size: CGSize) {
        let majorColor = AppTheme.danger.opacity(0.22)
        let minorColor = Color.white.opacity(0.06)

        var x: CGFloat = 0
        var col = 0
        while x <= size.width + 1 {
            let isMajor = col % 4 == 0
            var p = Path()
            p.move(to: CGPoint(x: x, y: 0))
            p.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(p, with: .color(isMajor ? majorColor : minorColor), lineWidth: isMajor ? 1 : 0.5)
            x += gridMinor
            col += 1
        }

        var y: CGFloat = 0
        var row = 0
        while y <= size.height + 1 {
            let isMajor = row % 4 == 0
            var p = Path()
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: size.width, y: y))
            context.stroke(p, with: .color(isMajor ? majorColor : minorColor), lineWidth: isMajor ? 1 : 0.5)
            y += gridMinor
            row += 1
        }
    }

    private func drawWave(context: inout GraphicsContext, size: CGSize) {
        guard samples.count >= 2 else {
            if isLive, samples.isEmpty {
                drawIdleBaseline(context: &context, size: size)
            }
            return
        }

        let slice = samples
        guard let minV = slice.min(), let maxV = slice.max() else { return }
        let span = max(maxV - minV, 0.25)
        let pad: CGFloat = 10
        let h = size.height - pad * 2

        var path = Path()
        for (i, v) in slice.enumerated() {
            let t = CGFloat(i) / CGFloat(max(slice.count - 1, 1))
            let x = t * size.width
            let ny = (CGFloat(v - minV) / CGFloat(span))
            let y = pad + h * (1 - ny)
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }

        context.stroke(
            path,
            with: .color(AppTheme.accent),
            style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round)
        )
    }

    /// Subtle “flatline” shimmer while waiting for first samples.
    private func drawIdleBaseline(context: inout GraphicsContext, size: CGSize) {
        let mid = size.height / 2
        var p = Path()
        p.move(to: CGPoint(x: 0, y: mid))
        p.addLine(to: CGPoint(x: size.width, y: mid))
        context.stroke(p, with: .color(AppTheme.accent.opacity(0.35)), lineWidth: 1)
    }

    private func drawSweep(context: inout GraphicsContext, size: CGSize, date: Date) {
        let t = date.timeIntervalSinceReferenceDate
        let period = 2.4
        let phase = CGFloat(t.truncatingRemainder(dividingBy: period) / period)
        let x = phase * size.width
        var p = Path()
        p.move(to: CGPoint(x: x, y: 0))
        p.addLine(to: CGPoint(x: x, y: size.height))
        context.stroke(p, with: .color(Color.white.opacity(0.4)), lineWidth: 2)
    }
}
