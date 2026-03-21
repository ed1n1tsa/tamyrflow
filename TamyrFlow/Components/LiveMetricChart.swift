import SwiftUI
import Charts

struct LiveMetricChart: View {
    let title: String
    let data: [ChartPoint]
    var unit: String = ""
    var color: Color = AppTheme.accent
    var yDomain: ClosedRange<Double>? = nil

    private var resolvedYDomain: ClosedRange<Double> {
        if let yDomain { return yDomain }
        let vals = data.map(\.value)
        guard !vals.isEmpty else { return 0...1 }
        let minV = vals.min() ?? 0
        let maxV = vals.max() ?? 1
        let pad = max((maxV - minV) * 0.2, 1)
        return (minV - pad)...(maxV + pad)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.white.opacity(0.65))
            if data.isEmpty {
                Text(L10n.Chart.emptyHint)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.35))
                    .frame(maxWidth: .infinity, minHeight: 120, alignment: .center)
            } else {
                let yLo = resolvedYDomain.lowerBound
                let yHi = resolvedYDomain.upperBound
                Chart(data) { point in
                    LineMark(
                        x: .value("t", point.id),
                        y: .value("v", point.value)
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(color)
                    // Explicit baseline prevents AreaMark fill from stretching through the whole ScrollView (Swift Charts quirk).
                    AreaMark(
                        x: .value("t", point.id),
                        yStart: .value("base", yLo),
                        yEnd: .value("v", min(max(point.value, yLo), yHi))
                    )
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.35), color.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .chartXAxis(.hidden)
                .chartYScale(domain: resolvedYDomain)
                .chartYAxis {
                    AxisMarks(position: .leading) { v in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(.white.opacity(0.12))
                        AxisValueLabel {
                            if let d = v.as(Double.self) {
                                Text(formatY(d))
                                    .font(.caption2)
                                    .foregroundStyle(.white.opacity(0.45))
                            }
                        }
                    }
                }
                .frame(height: 160)
                .clipped()
                .contentShape(Rectangle())
            }
        }
    }

    /// Avoid `String(format:)` here: `unit` can be `"%"` and mixed specifiers are easy to get wrong; chart values are whole numbers for our metrics.
    private func formatY(_ d: Double) -> String {
        let n = Int(d.rounded())
        if unit.isEmpty {
            return "\(n)"
        }
        return "\(n) \(unit)"
    }
}
