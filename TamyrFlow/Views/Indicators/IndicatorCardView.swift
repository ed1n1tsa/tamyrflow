import Charts
import SwiftUI

struct IndicatorCardView: View {
    let card: IndicatorCardModel

    var body: some View {
        HStack(spacing: 12) {
            iconBadge

            VStack(alignment: .leading, spacing: 6) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.Indicators.title(for: card.kind))
                        .font(AppFont.interBold(15))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(L10n.Indicators.unit(for: card.kind))
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)
                }

                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(formattedValue)
                        .font(AppFont.interBold(26))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)

                    if let trend = card.trendPercent {
                        trendLabel(trend)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            sparkline
                .frame(width: 88, height: 48)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(ProfileTheme.muted.opacity(0.7))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ProfileTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
                )
        )
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(card.kind.accent.opacity(0.22))
                .frame(width: 44, height: 44)
            Image(systemName: card.kind.iconSystemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(card.kind.accent)
        }
    }

    private func trendLabel(_ percent: Double) -> some View {
        let down = percent < 0
        let arrow = down ? "↓" : "↑"
        let absPct = abs(percent)
        let text: String
        if absPct < 1, absPct > 0 {
            text = String(format: "%@ %.1f%% %@", arrow, absPct, L10n.Indicators.trendAvg)
        } else {
            text = String(format: "%@ %.0f%% %@", arrow, absPct, L10n.Indicators.trendAvg)
        }
        return Text(text)
            .font(AppFont.interBold(11))
            .foregroundStyle(Color(red: 0.30, green: 0.85, blue: 0.55))
            .lineLimit(1)
            .minimumScaleFactor(0.8)
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

    @ViewBuilder
    private var sparkline: some View {
        let points = chartPoints
        let accent = card.primaryValue == nil ? card.kind.accent.opacity(0.35) : card.kind.accent
        if points.isEmpty {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(card.kind.accent.opacity(0.12))
        } else if card.kind.usesBarChart {
            Chart(points) { p in
                BarMark(
                    x: .value("d", p.id),
                    y: .value("v", p.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [accent, accent.opacity(0.45)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .cornerRadius(2)
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartLegend(.hidden)
        } else {
            let yLo = (points.map(\.value).min() ?? 0) * 0.92
            let yHi = max((points.map(\.value).max() ?? 1) * 1.08, yLo + 1)
            Chart(points) { p in
                LineMark(
                    x: .value("d", p.id),
                    y: .value("v", p.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(accent)
                .lineStyle(StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))

                AreaMark(
                    x: .value("d", p.id),
                    yStart: .value("base", yLo),
                    yEnd: .value("v", p.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [accent.opacity(0.35), accent.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartXAxis(.hidden)
            .chartYAxis(.hidden)
            .chartYScale(domain: yLo...yHi)
            .chartLegend(.hidden)
        }
    }

    private var chartPoints: [ChartPoint] {
        let nonzero = card.series.filter { $0.value > 0 }
        if !nonzero.isEmpty {
            return nonzero.enumerated().map { ChartPoint(id: $0.offset, value: $0.element.value) }
        }
        // Soft placeholder wave when no measurements yet.
        let demo: [Double] = [0.35, 0.55, 0.42, 0.68, 0.5, 0.72, 0.58]
        return demo.enumerated().map { ChartPoint(id: $0.offset, value: $0.element) }
    }

    private static func formatThousands(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = " "
        f.usesGroupingSeparator = true
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }
}
