import Combine
import Foundation
import Supabase

/// Pulse-style service for SpO₂ / temperature / blood pressure / steps.
@MainActor
final class VitalMetricService: ObservableObject {
    let kind: IndicatorKind

    @Published var period: PulsePeriod = .week
    @Published var rangeEnd: Date = Calendar.current.startOfDay(for: Date())
    @Published private(set) var measurements: [VitalMeasurement] = []
    @Published private(set) var chartPoints: [PulseChartPoint] = []
    @Published private(set) var stats = PulsePeriodStats()
    @Published private(set) var recent: [VitalMeasurement] = []
    @Published private(set) var isLoading = false
    @Published private(set) var syncState: PulseSyncState = .idle
    @Published private(set) var overlayMode: PulseOverlayMode = .sync
    @Published private(set) var lastSyncDebug: String = ""
    @Published var lastError: String?

    private let auth: AuthService
    private let health: VeepooHealthService
    private let ble: BleService

    init(kind: IndicatorKind, auth: AuthService, health: VeepooHealthService, ble: BleService) {
        precondition(kind != .heartRate && kind != .sleep, "Use Pulse/Sleep pages for those metrics")
        self.kind = kind
        self.auth = auth
        self.health = health
        self.ble = ble
    }

    var rangeStart: Date {
        let cal = Calendar.current
        switch period {
        case .day:
            return cal.startOfDay(for: rangeEnd)
        case .week, .month:
            return cal.date(byAdding: .day, value: -(period.dayCount - 1), to: rangeEnd) ?? rangeEnd
        }
    }

    var isWatchConnected: Bool {
        switch ble.connectionStatus {
        case .connected, .verified: return true
        default: return false
        }
    }

    var lastMeasurement: VitalMeasurement? {
        measurements.filter { $0.recordedAt >= rangeStart }.last ?? measurements.last
    }

    var unit: String { L10n.Indicators.unit(for: kind) }

    func setPeriod(_ period: PulsePeriod) async {
        self.period = period
        rangeEnd = Calendar.current.startOfDay(for: Date())
        await refresh()
    }

    func refresh() async {
        guard auth.session?.user.id != nil else {
            measurements = []
            chartPoints = []
            stats = PulsePeriodStats()
            recent = []
            return
        }
        isLoading = true
        defer { isLoading = false }
        await loadFromSupabase()
        rebuildDerived()
    }

    func cancelSyncOverlay() {
        if case .loading = syncState {
            syncState = .idle
        }
    }

    /// Refresh stored data (no live test). Steps also pull realtime totals from the band.
    func syncAvailableSources() async {
        overlayMode = .sync
        syncState = .loading
        let watchdog = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 35_000_000_000)
            if case .loading = self.syncState {
                self.syncState = .error("timeout")
            }
        }
        defer { watchdog.cancel() }

        var inserted = 0
        var parts: [String] = ["kind: \(kind.metricKey)"]

        do {
            if kind == .steps, isWatchConnected {
                let totals = await health.fetchRealtimeStepTotals()
                if let steps = totals.steps, steps >= 0 {
                    inserted += await persistSample(
                        date: Date(),
                        value: Double(steps),
                        secondary: nil,
                        source: .device,
                        deviceLabel: "Tamyr Watch"
                    )
                    parts.append("steps: \(steps)")
                } else {
                    parts.append("steps: none")
                }
            } else if !isWatchConnected {
                parts.append("watch: off")
            } else {
                parts.append("sync: reload-only")
            }

            await loadFromSupabase()
            rebuildDerived()
            lastSyncDebug = parts.joined(separator: " | ")
            print("[VitalMetric] \(lastSyncDebug)")

            if case .loading = syncState {
                if !isWatchConnected && measurements.isEmpty {
                    syncState = .noSource
                } else if inserted == 0 && measurements.isEmpty {
                    syncState = .noNewData
                } else if inserted == 0 {
                    syncState = .noNewData
                } else {
                    syncState = .success
                }
            }
        } catch {
            lastError = error.localizedDescription
            if case .loading = syncState {
                syncState = .error(error.localizedDescription)
            }
        }
    }

    /// Explicit measure on the watch → Supabase.
    func measureNow() async {
        guard isWatchConnected else {
            syncState = .noSource
            return
        }
        if kind == .temperature, !health.supportsTemperature {
            syncState = .error("unsupported")
            lastError = L10n.Err.tempUnsupported
            return
        }

        overlayMode = .measure
        syncState = .loading
        let watchdog = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 55_000_000_000)
            if case .loading = self.syncState, self.overlayMode == .measure {
                self.syncState = .error("timeout")
            }
        }
        defer { watchdog.cancel() }

        var parts: [String] = ["mode: measure", "kind: \(kind.metricKey)"]
        do {
            let sample: (date: Date, value: Double, secondary: Double?)?
            switch kind {
            case .spo2:
                if let s = await health.captureLiveOxygenSample() {
                    sample = (s.date, s.spo2, nil)
                    parts.append("live: \(Int(s.spo2))%")
                } else {
                    sample = nil
                    parts.append("live: none")
                }
            case .temperature:
                if let s = await health.captureLiveTemperatureSample() {
                    sample = (s.date, s.celsius, nil)
                    parts.append(String(format: "live: %.1f", s.celsius))
                } else {
                    sample = nil
                    parts.append("live: none")
                }
            case .bloodPressure:
                if let s = await health.captureLiveBloodPressureSample() {
                    sample = (s.date, s.systolic, s.diastolic)
                    parts.append("live: \(Int(s.systolic))/\(Int(s.diastolic))")
                } else {
                    sample = nil
                    parts.append("live: none")
                }
            case .steps:
                let totals = await health.fetchRealtimeStepTotals()
                if let steps = totals.steps, steps >= 0 {
                    sample = (Date(), Double(steps), nil)
                    parts.append("live: \(steps)")
                } else {
                    sample = nil
                    parts.append("live: none")
                }
            default:
                sample = nil
            }

            guard let sample else {
                lastSyncDebug = parts.joined(separator: " · ")
                print("[VitalMetric] \(lastSyncDebug)")
                if case .loading = syncState {
                    syncState = .error("measure_failed")
                }
                return
            }

            let inserted = await persistSample(
                date: sample.date,
                value: sample.value,
                secondary: sample.secondary,
                source: .device,
                deviceLabel: "Tamyr Watch"
            )
            parts.append("insert: \(inserted)")
            await loadFromSupabase()
            rebuildDerived()
            lastSyncDebug = parts.joined(separator: " · ")
            print("[VitalMetric] \(lastSyncDebug)")

            if case .loading = syncState {
                syncState = inserted > 0 ? .success : .error("persist_failed")
            }
        } catch {
            lastError = error.localizedDescription
            if case .loading = syncState {
                syncState = .error(error.localizedDescription)
            }
        }
    }

    func loadHistory(limit: Int, offset: Int) async -> [VitalMeasurement] {
        guard let uid = auth.session?.user.id else { return [] }
        struct Row: Decodable {
            let id: UUID
            let value: Double
            let value_secondary: Double?
            let recorded_at: String
            let source: String
        }
        do {
            let response: PostgrestResponse<[Row]> = try await auth.client
                .from("measurements")
                .select("id,value,value_secondary,recorded_at,source")
                .eq("user_id", value: uid.uuidString)
                .eq("metric", value: kind.metricKey)
                .order("recorded_at", ascending: false)
                .range(from: offset, to: offset + max(limit - 1, 0))
                .execute()
            return response.value.compactMap { row in
                guard let date = Self.parseTimestamp(row.recorded_at) else { return nil }
                let source = PulseSource(rawValue: row.source) ?? .manual
                return VitalMeasurement(
                    id: row.id,
                    value: row.value,
                    valueSecondary: row.value_secondary,
                    recordedAt: date,
                    source: source,
                    deviceLabel: Self.defaultDeviceLabel(for: source)
                )
            }
        } catch {
            lastError = error.localizedDescription
            return []
        }
    }

    // MARK: - Private

    private func loadFromSupabase() async {
        guard let uid = auth.session?.user.id else { return }
        let cal = Calendar.current
        let fetchStart = cal.date(byAdding: .day, value: -period.dayCount, to: rangeStart) ?? rangeStart
        let endExclusive = cal.date(byAdding: .day, value: 1, to: rangeEnd) ?? rangeEnd.addingTimeInterval(86_400)
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        struct Row: Decodable {
            let id: UUID
            let value: Double
            let value_secondary: Double?
            let recorded_at: String
            let source: String
        }

        do {
            let response: PostgrestResponse<[Row]> = try await auth.client
                .from("measurements")
                .select("id,value,value_secondary,recorded_at,source")
                .eq("user_id", value: uid.uuidString)
                .eq("metric", value: kind.metricKey)
                .gte("recorded_at", value: iso.string(from: fetchStart))
                .lt("recorded_at", value: iso.string(from: endExclusive))
                .order("recorded_at", ascending: true)
                .execute()

            measurements = response.value.compactMap { row in
                guard let date = Self.parseTimestamp(row.recorded_at) else { return nil }
                let source = PulseSource(rawValue: row.source) ?? .manual
                return VitalMeasurement(
                    id: row.id,
                    value: row.value,
                    valueSecondary: row.value_secondary,
                    recordedAt: date,
                    source: source,
                    deviceLabel: Self.defaultDeviceLabel(for: source)
                )
            }
        } catch {
            lastError = error.localizedDescription
            measurements = []
        }
    }

    private func rebuildDerived() {
        let endExclusive = rangeEnd.addingTimeInterval(86_400)
        let inRange = measurements.filter { $0.recordedAt >= rangeStart && $0.recordedAt < endExclusive }
        chartPoints = buildChartPoints(from: inRange)
        stats = buildStats(current: inRange, all: measurements)
        recent = Array(inRange.sorted { $0.recordedAt > $1.recordedAt }.prefix(3))
    }

    private func buildChartPoints(from rows: [VitalMeasurement]) -> [PulseChartPoint] {
        guard !rows.isEmpty else { return [] }
        let cal = Calendar.current

        switch period {
        case .day:
            var points: [PulseChartPoint] = []
            var prev: Date?
            for r in rows {
                let connected: Bool
                if let prev {
                    connected = r.recordedAt.timeIntervalSince(prev) <= 45 * 60
                } else {
                    connected = false
                }
                points.append(
                    PulseChartPoint(
                        id: r.id.uuidString,
                        date: r.recordedAt,
                        value: r.value,
                        isConnected: connected
                    )
                )
                prev = r.recordedAt
            }
            return points

        case .week, .month:
            var buckets: [String: (sum: Double, count: Int, day: Date, last: Double)] = [:]
            for r in rows {
                let day = cal.startOfDay(for: r.recordedAt)
                let key = GoalPeriodMath.dateOnlyString(day)
                var b = buckets[key] ?? (0, 0, day, 0)
                if kind == .steps {
                    b.sum = max(b.sum, r.value)
                    b.count = 1
                    b.last = b.sum
                } else {
                    b.sum += r.value
                    b.count += 1
                    b.last = r.value
                }
                buckets[key] = b
            }
            let keys = buckets.keys.sorted()
            var points: [PulseChartPoint] = []
            var prevDay: Date?
            for key in keys {
                guard let b = buckets[key], b.count > 0 else { continue }
                let value = kind == .steps ? b.last : (b.sum / Double(b.count))
                let connected: Bool
                if let prevDay {
                    let diff = cal.dateComponents([.day], from: prevDay, to: b.day).day ?? 99
                    connected = diff == 1
                } else {
                    connected = false
                }
                points.append(
                    PulseChartPoint(
                        id: key,
                        date: b.day,
                        value: value,
                        isConnected: connected
                    )
                )
                prevDay = b.day
            }
            return points
        }
    }

    private func buildStats(current: [VitalMeasurement], all: [VitalMeasurement]) -> PulsePeriodStats {
        var s = PulsePeriodStats()
        guard !current.isEmpty else { return s }
        let values = current.map(\.value)
        if kind == .steps {
            s.average = values.last
        } else {
            s.average = values.reduce(0, +) / Double(values.count)
        }
        if let minRow = current.min(by: { $0.value < $1.value }) {
            s.minimum = minRow.value
            s.minimumAt = minRow.recordedAt
        }
        if let maxRow = current.max(by: { $0.value < $1.value }) {
            s.maximum = maxRow.value
            s.maximumAt = maxRow.recordedAt
        }

        let cal = Calendar.current
        let prevEnd = cal.date(byAdding: .day, value: -1, to: rangeStart) ?? rangeStart
        let prevStart = cal.date(byAdding: .day, value: -(period.dayCount - 1), to: prevEnd) ?? prevEnd
        let prev = all.filter { $0.recordedAt >= prevStart && $0.recordedAt < rangeStart }
        if let avg = s.average, !prev.isEmpty {
            let prevAvg: Double
            if kind == .steps {
                prevAvg = prev.map(\.value).max() ?? 0
            } else {
                prevAvg = prev.map(\.value).reduce(0, +) / Double(prev.count)
            }
            if prevAvg > 0 {
                s.trendPercent = ((avg - prevAvg) / prevAvg) * 100.0
            }
        }
        return s
    }

    @discardableResult
    private func persistSample(
        date: Date,
        value: Double,
        secondary: Double?,
        source: PulseSource,
        deviceLabel: String
    ) async -> Int {
        guard let uid = auth.session?.user.id else { return 0 }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let windowStart = date.addingTimeInterval(-90)
        let windowEnd = date.addingTimeInterval(90)

        struct Existing: Decodable { let id: UUID; let value: Double }
        if let response: PostgrestResponse<[Existing]> = try? await auth.client
            .from("measurements")
            .select("id,value")
            .eq("user_id", value: uid.uuidString)
            .eq("metric", value: kind.metricKey)
            .gte("recorded_at", value: iso.string(from: windowStart))
            .lte("recorded_at", value: iso.string(from: windowEnd))
            .limit(5)
            .execute(),
           response.value.contains(where: { abs($0.value - value) < 0.6 }) {
            return 0
        }

        struct Insert: Encodable {
            let user_id: String
            let metric: String
            let value: Double
            let value_secondary: Double?
            let unit: String
            let recorded_at: String
            let source: String
            let meta: [String: String]
        }

        do {
            try await auth.client
                .from("measurements")
                .insert(
                    Insert(
                        user_id: uid.uuidString,
                        metric: kind.metricKey,
                        value: value,
                        value_secondary: secondary,
                        unit: unit,
                        recorded_at: iso.string(from: date),
                        source: source.rawValue,
                        meta: ["device": deviceLabel, "type": "sample"]
                    )
                )
                .execute()
            return 1
        } catch {
            lastError = error.localizedDescription
            return 0
        }
    }

    private static func defaultDeviceLabel(for source: PulseSource) -> String {
        switch source {
        case .device: return "Tamyr Watch"
        case .appleHealth: return "Apple Health"
        case .manual: return "Manual"
        }
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

struct VitalMeasurement: Identifiable, Equatable, Hashable {
    let id: UUID
    let value: Double
    let valueSecondary: Double?
    let recordedAt: Date
    let source: PulseSource
    let deviceLabel: String?
}
