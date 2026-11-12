import Combine
import Foundation
import Supabase

@MainActor
final class PulseService: ObservableObject {
    @Published var period: PulsePeriod = .week
    /// Inclusive end day (start-of-day local).
    @Published var rangeEnd: Date = Calendar.current.startOfDay(for: Date())
    @Published private(set) var measurements: [PulseMeasurement] = []
    @Published private(set) var chartPoints: [PulseChartPoint] = []
    @Published private(set) var stats = PulsePeriodStats()
    @Published private(set) var recent: [PulseMeasurement] = []
    @Published private(set) var isLoading = false
    @Published private(set) var syncState: PulseSyncState = .idle
    /// Distinguishes overlay copy: sync vs explicit measure.
    @Published private(set) var overlayMode: PulseOverlayMode = .sync
    /// Last sync diagnostic (Xcode console + optional UI). Not user-facing copy.
    @Published private(set) var lastSyncDebug: String = ""
    @Published var lastError: String?

    private let auth: AuthService
    private let health: VeepooHealthService
    private let ble: BleService

    init(auth: AuthService, health: VeepooHealthService, ble: BleService) {
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

    var lastMeasurement: PulseMeasurement? {
        measurements.filter { $0.recordedAt >= rangeStart }.last ?? measurements.last
    }

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

    /// User dismissed the sync overlay (or soft-cancel).
    func cancelSyncOverlay() {
        if case .loading = syncState {
            syncState = .idle
            lastSyncDebug = (lastSyncDebug.isEmpty ? "" : lastSyncDebug + " | ") + "cancelled"
        }
    }

    /// Sync stored sources → measurements. Never starts a live HR test (App Store–honest «Обновить»).
    /// Always clears `.loading` (hard timeout) so the overlay cannot stick forever.
    func syncAvailableSources() async {
        overlayMode = .sync
        syncState = .loading
        let watchdog = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 35_000_000_000)
            if case .loading = self.syncState {
                self.syncState = .error("timeout")
                self.lastSyncDebug = (self.lastSyncDebug.isEmpty ? "" : self.lastSyncDebug + " | ") + "watchdog: 35s"
                print("[PulseSync] watchdog fired — clearing loading overlay")
            }
        }
        defer { watchdog.cancel() }

        var inserted = 0
        var parts: [String] = []
        let watchOK = isWatchConnected

        do {
            if watchOK {
                let result = await health.syncAndFetchHeartSamples(dayCount: 7)
                parts.append(result.debug)
                let before = inserted
                inserted += await persistSamples(result.samples, source: .device, deviceLabel: "Tamyr Watch")
                parts.append("deviceInsert: \(inserted - before)")
            } else {
                parts.append("watch: off")
            }

            let cal = Calendar.current
            let hkStart = cal.date(byAdding: .day, value: -30, to: cal.startOfDay(for: Date()))
                ?? Date().addingTimeInterval(-30 * 86_400)
            let hkEnd = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: Date())) ?? Date()
            let hkSamples = await HealthKitWellnessService.fetchHeartRateSamples(
                start: hkStart,
                end: hkEnd,
                timeoutSeconds: 8
            )
            let hkInserted = await persistSamples(hkSamples, source: .appleHealth, deviceLabel: "Apple Health")
            inserted += hkInserted
            parts.append("hk: \(hkSamples.count)/ins \(hkInserted)")

            await loadFromSupabase()
            rebuildDerived()
            lastSyncDebug = parts.joined(separator: " | ")
            print("[PulseSync] \(lastSyncDebug)")

            if case .loading = syncState {
                if !watchOK && hkSamples.isEmpty && measurements.isEmpty {
                    syncState = .noSource
                } else if inserted == 0 {
                    syncState = .noNewData
                } else {
                    syncState = .success
                }
            }
        } catch {
            lastError = error.localizedDescription
            lastSyncDebug = parts.joined(separator: " | ") + " | error: \(error.localizedDescription)"
            if case .loading = syncState {
                syncState = .error(error.localizedDescription)
            }
        }
    }

    /// Explicit «Измерить пульс»: live SDK test → Supabase + Apple Health.
    func measureHeartNow() async {
        guard isWatchConnected else {
            syncState = .noSource
            return
        }
        overlayMode = .measure
        syncState = .loading
        let watchdog = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 40_000_000_000)
            if case .loading = self.syncState, self.overlayMode == .measure {
                self.syncState = .error("timeout")
                self.lastSyncDebug = (self.lastSyncDebug.isEmpty ? "" : self.lastSyncDebug + " | ") + "measureWatchdog: 40s"
            }
        }
        defer { watchdog.cancel() }

        var parts: [String] = ["mode: measure"]
        do {
            guard let sample = await health.captureLiveHeartSample(timeoutSeconds: 25) else {
                parts.append("live: none")
                lastSyncDebug = parts.joined(separator: " · ")
                print("[PulseSync] \(lastSyncDebug)")
                if case .loading = syncState {
                    syncState = .error("measure_failed")
                }
                return
            }
            parts.append("live: \(Int(sample.bpm))")
            let inserted = await persistSamples([sample], source: .device, deviceLabel: "Tamyr Watch")
            parts.append("deviceInsert: \(inserted)")
            let hkOK = await HealthKitWellnessService.saveHeartRateSample(bpm: sample.bpm, at: sample.date)
            parts.append("hkWrite: \(hkOK ? 1 : 0)")

            await loadFromSupabase()
            rebuildDerived()
            lastSyncDebug = parts.joined(separator: " · ")
            print("[PulseSync] \(lastSyncDebug)")

            if case .loading = syncState {
                syncState = inserted > 0 ? .success : .error("persist_failed")
            }
        } catch {
            lastError = error.localizedDescription
            lastSyncDebug = parts.joined(separator: " · ") + " | error: \(error.localizedDescription)"
            if case .loading = syncState {
                syncState = .error(error.localizedDescription)
            }
        }
    }

    func loadHistory(limit: Int, offset: Int) async -> [PulseMeasurement] {
        guard let uid = auth.session?.user.id else { return [] }
        struct Row: Decodable {
            let id: UUID
            let value: Double
            let recorded_at: String
            let source: String
        }
        do {
            let response: PostgrestResponse<[Row]> = try await auth.client
                .from("measurements")
                .select("id,value,recorded_at,source")
                .eq("user_id", value: uid.uuidString)
                .eq("metric", value: "heart_rate")
                .order("recorded_at", ascending: false)
                .range(from: offset, to: offset + max(limit - 1, 0))
                .execute()
            return response.value.compactMap { row in
                guard let date = Self.parseTimestamp(row.recorded_at) else { return nil }
                let source = PulseSource(rawValue: row.source) ?? .manual
                return PulseMeasurement(
                    id: row.id,
                    value: row.value,
                    recordedAt: date,
                    source: source,
                    deviceLabel: Self.defaultDeviceLabel(for: source),
                    recordType: "sample"
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
            let recorded_at: String
            let source: String
        }

        do {
            let response: PostgrestResponse<[Row]> = try await auth.client
                .from("measurements")
                .select("id,value,recorded_at,source")
                .eq("user_id", value: uid.uuidString)
                .eq("metric", value: "heart_rate")
                .gte("recorded_at", value: iso.string(from: fetchStart))
                .lt("recorded_at", value: iso.string(from: endExclusive))
                .order("recorded_at", ascending: true)
                .execute()

            measurements = response.value.compactMap { row in
                guard let date = Self.parseTimestamp(row.recorded_at) else { return nil }
                let source = PulseSource(rawValue: row.source) ?? .manual
                return PulseMeasurement(
                    id: row.id,
                    value: row.value,
                    recordedAt: date,
                    source: source,
                    deviceLabel: Self.defaultDeviceLabel(for: source),
                    recordType: "sample"
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

    private func buildChartPoints(from rows: [PulseMeasurement]) -> [PulseChartPoint] {
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
            var buckets: [String: (sum: Double, count: Int, day: Date)] = [:]
            for r in rows {
                let day = cal.startOfDay(for: r.recordedAt)
                let key = GoalPeriodMath.dateOnlyString(day)
                var b = buckets[key] ?? (0, 0, day)
                b.sum += r.value
                b.count += 1
                buckets[key] = b
            }
            let keys = buckets.keys.sorted()
            var points: [PulseChartPoint] = []
            var prevDay: Date?
            for key in keys {
                guard let b = buckets[key], b.count > 0 else { continue }
                let avg = b.sum / Double(b.count)
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
                        value: avg,
                        isConnected: connected
                    )
                )
                prevDay = b.day
            }
            return points
        }
    }

    private func buildStats(current: [PulseMeasurement], all: [PulseMeasurement]) -> PulsePeriodStats {
        var s = PulsePeriodStats()
        guard !current.isEmpty else { return s }
        let values = current.map(\.value)
        s.average = values.reduce(0, +) / Double(values.count)
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
            let prevAvg = prev.map(\.value).reduce(0, +) / Double(prev.count)
            if prevAvg > 0 {
                s.trendPercent = ((avg - prevAvg) / prevAvg) * 100.0
            }
        }
        return s
    }

    @discardableResult
    private func persistSamples(
        _ samples: [(date: Date, bpm: Double)],
        source: PulseSource,
        deviceLabel: String
    ) async -> Int {
        guard let uid = auth.session?.user.id else { return 0 }
        guard !samples.isEmpty else { return 0 }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // Cap to recent points so overlay cannot spend minutes on hundreds of round-trips.
        let capped = Array(samples.suffix(80))
        var inserted = 0
        for sample in capped {
            if case .idle = syncState { break }
            if case .error = syncState { break }
            let recorded = sample.date
            let windowStart = recorded.addingTimeInterval(-90)
            let windowEnd = recorded.addingTimeInterval(90)

            struct Existing: Decodable { let id: UUID; let value: Double }
            if let response: PostgrestResponse<[Existing]> = try? await auth.client
                .from("measurements")
                .select("id,value")
                .eq("user_id", value: uid.uuidString)
                .eq("metric", value: "heart_rate")
                .gte("recorded_at", value: iso.string(from: windowStart))
                .lte("recorded_at", value: iso.string(from: windowEnd))
                .limit(5)
                .execute(),
               response.value.contains(where: { abs($0.value - sample.bpm) < 0.6 }) {
                continue
            }

            struct Insert: Encodable {
                let user_id: String
                let metric: String
                let value: Double
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
                            metric: "heart_rate",
                            value: sample.bpm.rounded(),
                            unit: "bpm",
                            recorded_at: iso.string(from: recorded),
                            source: source.rawValue,
                            meta: ["device": deviceLabel, "type": "sample"]
                        )
                    )
                    .execute()
                inserted += 1
            } catch {
                // Keep going; individual row failures shouldn't abort sync.
            }
        }
        return inserted
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
