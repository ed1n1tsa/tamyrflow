import Charts
import SwiftUI

struct PulseChartView: View {
    let points: [PulseChartPoint]
    let period: PulsePeriod
    @Binding var selected: PulseChartPoint?
    var emptyMessage: String
    var emptySub: String

    private let accent = Color(red: 1.0, green: 0.28, blue: 0.42)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if points.isEmpty {
                emptyState
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
            } else {
                chart
                    .frame(height: 200)
                if let selected {
                    selectionBanner(selected)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "heart.fill")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(ProfileTheme.accent.opacity(0.55))
            Text(emptyMessage)
                .font(AppFont.interBold(15))
                .foregroundStyle(.white)
            Text(emptySub)
                .font(AppFont.interBold(12))
                .foregroundStyle(ProfileTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 12)
        }
    }

    private var segmented: [(segment: Int, point: PulseChartPoint)] {
        var seg = 0
        var out: [(Int, PulseChartPoint)] = []
        for (idx, p) in points.enumerated() {
            if idx > 0, !p.isConnected { seg += 1 }
            out.append((seg, p))
        }
        return out
    }

    private var chart: some View {
        Chart {
            ForEach(segmented, id: \.point.id) { item in
                LineMark(
                    x: .value("t", item.point.date),
                    y: .value("v", item.point.value),
                    series: .value("s", item.segment)
                )
                .foregroundStyle(accent)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))

                AreaMark(
                    x: .value("t", item.point.date),
                    y: .value("v", item.point.value),
                    series: .value("s", item.segment)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [accent.opacity(0.28), accent.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)

                PointMark(
                    x: .value("t", item.point.date),
                    y: .value("v", item.point.value)
                )
                .symbolSize(selected?.id == item.point.id ? 64 : 24)
                .foregroundStyle(accent)
            }

            if let selected {
                RuleMark(x: .value("sel", selected.date))
                    .foregroundStyle(Color.white.opacity(0.25))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
            }
        }
        .chartXScale(domain: xDomain)
        .chartYScale(domain: yDomain)
        .chartXAxis {
            AxisMarks(values: xTickValues) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.white.opacity(0.08))
                AxisValueLabel {
                    if let date = value.as(Date.self) {
                        Text(xLabel(date))
                            .font(.caption2)
                            .foregroundStyle(ProfileTheme.muted)
                    }
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: [0, 30, 60, 90, 120]) { v in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(Color.white.opacity(0.10))
                AxisValueLabel {
                    if let d = v.as(Double.self) {
                        Text("\(Int(d))")
                            .font(.caption2)
                            .foregroundStyle(ProfileTheme.muted)
                    }
                }
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geo in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard let plot = proxy.plotFrame else { return }
                                let x = value.location.x - geo[plot].origin.x
                                guard let date: Date = proxy.value(atX: x) else { return }
                                selected = nearest(to: date)
                            }
                    )
            }
        }
    }

    private func selectionBanner(_ point: PulseChartPoint) -> some View {
        Text("\(PulseFormatters.bpmWithUnit(point.value)) · \(PulseFormatters.shortDateTime(point.date))")
            .font(AppFont.interBold(12))
            .foregroundStyle(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule(style: .continuous)
                    .fill(Color.black.opacity(0.35))
                    .overlay(Capsule().strokeBorder(ProfileTheme.cardBorder, lineWidth: 1))
            )
    }

    private var xDomain: ClosedRange<Date> {
        switch period {
        case .day:
            let start = Calendar.current.startOfDay(for: points.first?.date ?? Date())
            let end = start.addingTimeInterval(24 * 3600)
            return start...end
        case .week, .month:
            if let first = points.first?.date, let last = points.last?.date {
                return first...last
            }
            let now = Date()
            return now.addingTimeInterval(-6 * 86_400)...now
        }
    }

    private var yDomain: ClosedRange<Double> {
        let vals = points.map(\.value)
        let lo = min(vals.min() ?? 40, 40)
        let hi = max(vals.max() ?? 120, 120)
        return (lo * 0.9)...(hi * 1.08)
    }

    private var xTickValues: [Date] {
        switch period {
        case .day:
            let start = Calendar.current.startOfDay(for: points.first?.date ?? Date())
            return [0, 6, 12, 18, 24].compactMap { Calendar.current.date(byAdding: .hour, value: $0, to: start) }
        case .week:
            return points.map(\.date)
        case .month:
            // Sparse labels.
            return points.enumerated().compactMap { idx, p in
                idx % max(points.count / 5, 1) == 0 ? p.date : nil
            }
        }
    }

    private func xLabel(_ date: Date) -> String {
        switch period {
        case .day:
            let f = DateFormatter()
            f.locale = PulseFormatters.locale
            f.dateFormat = "HH:mm"
            return f.string(from: date)
        case .week:
            return PulseFormatters.weekdayShort(date)
        case .month:
            let f = DateFormatter()
            f.locale = PulseFormatters.locale
            f.setLocalizedDateFormatFromTemplate("d MMM")
            return f.string(from: date)
        }
    }

    private func nearest(to date: Date) -> PulseChartPoint? {
        points.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }
}
