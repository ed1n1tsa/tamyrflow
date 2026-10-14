import Combine
import Foundation
import Supabase

@MainActor
final class IndicatorsService: ObservableObject {
    @Published var period: IndicatorsPeriod = .days7
    /// Inclusive end day (local start-of-day).
    @Published var rangeEnd: Date = Calendar.current.startOfDay(for: Date())
    @Published private(set) var cards: [IndicatorCardModel] = []
    @Published private(set) var isLoading = false
    @Published var lastError: String?

    private let auth: AuthService

    init(auth: AuthService) {
        self.auth = auth
        cards = IndicatorKind.allCases.map { emptyCard(for: $0) }
    }

    var rangeStart: Date {
        let cal = Calendar.current
        return cal.date(byAdding: .day, value: -(period.dayCount - 1), to: rangeEnd)
            ?? rangeEnd.addingTimeInterval(-Double(period.dayCount - 1) * 86_400)
    }

    func setPeriod(_ period: IndicatorsPeriod) async {
        self.period = period
        rangeEnd = Calendar.current.startOfDay(for: Date())
        await refresh()
    }

    func setRangeEnd(_ date: Date) async {
        rangeEnd = Calendar.current.startOfDay(for: date)
        await refresh()
    }

    func refresh() async {
        guard let uid = auth.session?.user.id else {
            cards = IndicatorKind.allCases.map { emptyCard(for: $0) }
            return
        }
        isLoading = true
        lastError = nil
        defer { isLoading = false }

        let cal = Calendar.current
        let start = rangeStart
        let endExclusive = cal.date(byAdding: .day, value: 1, to: rangeEnd) ?? rangeEnd.addingTimeInterval(86_400)
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        struct Row: Decodable {
            let metric: String
            let value: Double
            let value_secondary: Double?
            let recorded_at: String
        }

        do {
            let response: PostgrestResponse<[Row]> = try await auth.client
                .from("measurements")
                .select("metric,value,value_secondary,recorded_at")
                .eq("user_id", value: uid.uuidString)
                .gte("recorded_at", value: iso.string(from: start))
                .lt("recorded_at", value: iso.string(from: endExclusive))
                .order("recorded_at", ascending: true)
                .execute()

            let parsed: [(metric: String, value: Double, value_secondary: Double?, recorded_at: Date)] = response.value.compactMap { row in
                guard let date = Self.parseTimestamp(row.recorded_at) else { return nil }
                return (row.metric, row.value, row.value_secondary, date)
            }

            var built: [IndicatorCardModel] = []
            for kind in IndicatorKind.allCases {
                let rows = parsed.filter { $0.metric == kind.metricKey }
                built.append(buildCard(kind: kind, rows: rows, start: start, end: rangeEnd))
            }
            cards = built
        } catch {
            lastError = error.localizedDescription
            cards = IndicatorKind.allCases.map { emptyCard(for: $0) }
        }
    }

    // MARK: - Builders

    private func emptyCard(for kind: IndicatorKind) -> IndicatorCardModel {
        IndicatorCardModel(
            kind: kind,
            primaryValue: nil,
            secondaryValue: nil,
            trendPercent: nil,
            series: placeholderSeries()
        )
    }

    private func placeholderSeries() -> [IndicatorDayPoint] {
        let cal = Calendar.current
        var points: [IndicatorDayPoint] = []
        var day = rangeStart
        while day <= rangeEnd {
            let key = GoalPeriodMath.dateOnlyString(day)
            points.append(IndicatorDayPoint(dayKey: key, date: day, value: 0, valueSecondary: nil))
            day = cal.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86_400)
        }
        return points
    }

    private func buildCard(
        kind: IndicatorKind,
        rows: [(metric: String, value: Double, value_secondary: Double?, recorded_at: Date)],
        start: Date,
        end: Date
    ) -> IndicatorCardModel {
        let cal = Calendar.current
        var byDay: [String: (sum: Double, sum2: Double, count: Int, last: Double, last2: Double?)] = [:]

        for r in rows {
            let day = cal.startOfDay(for: r.recorded_at)
            let key = GoalPeriodMath.dateOnlyString(day)
            var bucket = byDay[key] ?? (0, 0, 0, 0, nil)
            switch kind {
            case .steps, .sleep:
                // Daily totals — keep max (device upsert grows through the day).
                bucket.sum = max(bucket.sum, r.value)
                bucket.count = 1
                bucket.last = bucket.sum
            case .bloodPressure:
                bucket.sum += r.value
                bucket.sum2 += r.value_secondary ?? 0
                bucket.count += 1
                bucket.last = r.value
                bucket.last2 = r.value_secondary
            default:
                bucket.sum += r.value
                bucket.count += 1
                bucket.last = r.value
            }
            byDay[key] = bucket
        }

        var series: [IndicatorDayPoint] = []
        var day = start
        while day <= end {
            let key = GoalPeriodMath.dateOnlyString(day)
            if let b = byDay[key], b.count > 0 {
                let value: Double
                let secondary: Double?
                switch kind {
                case .steps, .sleep:
                    value = b.sum
                    secondary = nil
                case .bloodPressure:
                    value = b.last
                    secondary = b.last2
                default:
                    value = b.sum / Double(b.count)
                    secondary = nil
                }
                series.append(IndicatorDayPoint(dayKey: key, date: day, value: value, valueSecondary: secondary))
            } else {
                series.append(IndicatorDayPoint(dayKey: key, date: day, value: 0, valueSecondary: nil))
            }
            day = cal.date(byAdding: .day, value: 1, to: day) ?? day.addingTimeInterval(86_400)
        }

        let nonzero = series.filter { $0.value > 0 }
        let primary: Double?
        let secondary: Double?
        if let last = nonzero.last {
            primary = last.value
            secondary = last.valueSecondary
        } else {
            primary = nil
            secondary = nil
        }

        let trend = trendPercent(from: nonzero.map(\.value))
        return IndicatorCardModel(
            kind: kind,
            primaryValue: primary,
            secondaryValue: secondary,
            trendPercent: trend,
            series: series
        )
    }

    /// Compare mean of second half vs first half of nonzero samples.
    private func trendPercent(from values: [Double]) -> Double? {
        guard values.count >= 2 else { return nil }
        let mid = values.count / 2
        let first = Array(values.prefix(mid))
        let second = Array(values.suffix(values.count - mid))
        guard !first.isEmpty, !second.isEmpty else { return nil }
        let a = first.reduce(0, +) / Double(first.count)
        let b = second.reduce(0, +) / Double(second.count)
        guard a > 0 else { return nil }
        return ((b - a) / a) * 100.0
    }

    private static func parseTimestamp(_ raw: String) -> Date? {
        let frac = ISO8601DateFormatter()
        frac.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = frac.date(from: raw) { return d }
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: raw)
    }
}
