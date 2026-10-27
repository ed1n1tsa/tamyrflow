import SwiftUI

struct IndicatorCardView: View {
    let card: IndicatorCardModel

    private let iconSize: CGFloat = 48
    private let sparkWidth: CGFloat = 96
    private let sparkHeight: CGFloat = 52

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            iconBadge

            VStack(alignment: .leading, spacing: 8) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(L10n.Indicators.title(for: card.kind))
                        .font(AppFont.interBold(16))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    Text(L10n.Indicators.unit(for: card.kind))
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)
                        .lineLimit(1)
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(formattedValue)
                        .font(AppFont.interBold(valueFontSize))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .layoutPriority(1)

                    if let trend = card.trendPercent {
                        trendLabel(trend)
                            .layoutPriority(0)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            IndicatorSparkline(
                values: chartValues,
                accent: card.kind.accent,
                style: card.kind.usesBarChart ? .bars : .line,
                isPlaceholder: card.primaryValue == nil
            )
            .frame(width: sparkWidth, height: sparkHeight)
            .layoutPriority(2)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(ProfileTheme.muted.opacity(0.55))
                .frame(width: 10)
        }
        .padding(.leading, 14)
        .padding(.trailing, 12)
        .padding(.vertical, 16)
        .frame(minHeight: 104)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 10 / 255, green: 28 / 255, blue: 56 / 255).opacity(0.92),
                            Color(red: 6 / 255, green: 20 / 255, blue: 42 / 255).opacity(0.88)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    ProfileTheme.cardBorder.opacity(0.95),
                                    ProfileTheme.cardBorder.opacity(0.35)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private var valueFontSize: CGFloat {
        switch card.kind {
        case .sleep, .bloodPressure: return 22
        case .steps: return 24
        default: return 28
        }
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            card.kind.accent.opacity(0.38),
                            card.kind.accent.opacity(0.12)
                        ],
                        center: .center,
                        startRadius: 2,
                        endRadius: iconSize * 0.55
                    )
                )
                .frame(width: iconSize, height: iconSize)
            Image(systemName: card.kind.iconSystemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(card.kind.accent)
                .shadow(color: card.kind.accent.opacity(0.45), radius: 6, y: 1)
        }
        .accessibilityHidden(true)
    }

    private func trendLabel(_ percent: Double) -> some View {
        let down = percent < 0
        let arrow = down ? "↓" : "↑"
        let absPct = abs(percent)
        let pctText: String
        if absPct > 0, absPct < 1 {
            pctText = String(format: "%.1f%%", absPct)
        } else {
            pctText = String(format: "%.0f%%", absPct)
        }
        return HStack(spacing: 3) {
            Text("\(arrow) \(pctText)")
                .font(AppFont.interBold(11))
            Text(L10n.Indicators.trendAvg)
                .font(AppFont.interBold(11))
                .opacity(0.9)
        }
        .foregroundStyle(Color(red: 0.35, green: 0.88, blue: 0.58))
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }

    private var formattedValue: String {
        guard let v = card.primaryValue else { return "—" }
        switch card.kind {
        case .heartRate, .spo2:
            return "\(Int(v.rounded()))"
        case .temperature:
            return String(format: "%.1f", v)
        case .bloodPressure:
            let sys = Int(v.rounded())
            let dia = Int((card.secondaryValue ?? 0).rounded())
            return "\(sys)/\(dia)"
        case .steps:
            return Self.formatThousands(Int(v.rounded()))
        case .sleep:
            let total = Int(v.rounded())
            let h = total / 60
            let m = total % 60
            return String(format: L10n.Indicators.sleepValueFormat, h, m)
        }
    }

    private var chartValues: [Double] {
        // Only real series — no fake waves (they looked like data next to "—").
        let nonzero = card.series.filter { $0.value > 0 }.map(\.value)
        if nonzero.count == 1 { return [nonzero[0], nonzero[0]] }
        return nonzero
    }

    private static func formatThousands(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = " "
        f.usesGroupingSeparator = true
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}

// MARK: - Sparkline (Canvas — tighter than Swift Charts in small cards)

private struct IndicatorSparkline: View {
    enum Style { case line, bars }

    let values: [Double]
    let accent: Color
    let style: Style
    var isPlaceholder: Bool = false

    var body: some View {
        Canvas { context, size in
            guard values.count >= 2, size.width > 1, size.height > 1 else { return }
            let ink = accent.opacity(isPlaceholder ? 0.45 : 1)
            switch style {
            case .line:
                drawLine(context: &context, size: size, color: ink)
            case .bars:
                drawBars(context: &context, size: size, color: ink)
            }
        }
        .accessibilityHidden(true)
    }

    private func drawLine(context: inout GraphicsContext, size: CGSize, color: Color) {
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 1
        let span = max(maxV - minV, 0.001)
        let padY: CGFloat = 3
        let usableH = size.height - padY * 2
        let stepX = size.width / CGFloat(values.count - 1)

        func point(at i: Int) -> CGPoint {
            let t = (values[i] - minV) / span
            let y = size.height - padY - CGFloat(t) * usableH
            return CGPoint(x: CGFloat(i) * stepX, y: y)
        }

        let points = (0..<values.count).map(point(at:))
        let line = smoothPath(points: points)

        var fill = line
        if let last = points.last, let first = points.first {
            fill.addLine(to: CGPoint(x: last.x, y: size.height))
            fill.addLine(to: CGPoint(x: first.x, y: size.height))
            fill.closeSubpath()
        }

        context.fill(
            fill,
            with: .linearGradient(
                Gradient(colors: [color.opacity(0.40), color.opacity(0.02)]),
                startPoint: CGPoint(x: size.width / 2, y: 0),
                endPoint: CGPoint(x: size.width / 2, y: size.height)
            )
        )
        context.stroke(
            line,
            with: .linearGradient(
                Gradient(colors: [color.opacity(0.85), color]),
                startPoint: .zero,
                endPoint: CGPoint(x: size.width, y: 0)
            ),
            style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round)
        )
    }

    private func drawBars(context: inout GraphicsContext, size: CGSize, color: Color) {
        let maxV = max(values.max() ?? 1, 0.001)
        let count = values.count
        let gap: CGFloat = 3
        let barW = max((size.width - gap * CGFloat(count - 1)) / CGFloat(count), 3)

        for (i, v) in values.enumerated() {
            let h = max(size.height * CGFloat(v / maxV), 4)
            let x = CGFloat(i) * (barW + gap)
            let y = size.height - h
            let rect = CGRect(x: x, y: y, width: barW, height: h)
            let path = Path(roundedRect: rect, cornerRadius: 2.5, style: .continuous)
            context.fill(
                path,
                with: .linearGradient(
                    Gradient(colors: [color, color.opacity(0.45)]),
                    startPoint: CGPoint(x: rect.midX, y: rect.minY),
                    endPoint: CGPoint(x: rect.midX, y: rect.maxY)
                )
            )
        }
    }

    private func smoothPath(points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        guard points.count > 1 else { return path }
        for i in 0..<(points.count - 1) {
            let p0 = points[max(i - 1, 0)]
            let p1 = points[i]
            let p2 = points[i + 1]
            let p3 = points[min(i + 2, points.count - 1)]
            let c1 = CGPoint(
                x: p1.x + (p2.x - p0.x) / 6,
                y: p1.y + (p2.y - p0.y) / 6
            )
            let c2 = CGPoint(
                x: p2.x - (p3.x - p1.x) / 6,
                y: p2.y - (p3.y - p1.y) / 6
            )
            path.addCurve(to: p2, control1: c1, control2: c2)
        }
        return path
    }
}
