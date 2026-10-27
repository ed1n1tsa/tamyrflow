import Foundation
import VeepooBleSDK
import Combine

@MainActor
final class VeepooHealthService: ObservableObject {
    @Published private(set) var operation: BleOperation = .idle
    @Published private(set) var readProgressText = ""
    @Published private(set) var heartRate: HeartRateReading?
    @Published private(set) var oxygen: OxygenReading?
    @Published private(set) var temperature: TemperatureReading?
    @Published private(set) var ecg: ECGReading?
    @Published private(set) var microTest: MicroTestReading?
    @Published private(set) var bloodPressure: BloodPressureReading?
    @Published private(set) var bloodGlucose: BloodGlucoseReading?
    @Published private(set) var lastError: String?
    /// Today’s total steps from the band (best-effort parse of SDK dictionary).
    @Published private(set) var todaySteps: Int?
    /// Today’s calories (kcal) from Veepoo step dictionary `Cal`.
    @Published private(set) var todayCaloriesKcal: Double?
    /// Today’s distance (km) from Veepoo step dictionary `Dis`.
    @Published private(set) var todayDistanceKm: Double?
    /// Number of sleep segments returned for the last successful sleep read.
    @Published private(set) var sleepSegmentsToday: Int?
    /// Total sleep duration in minutes (last night / day-1 preferred, then day-0).
    @Published private(set) var todaySleepMinutes: Int?
    /// Full-screen overlay while measuring / syncing (official-app style).
    @Published private(set) var measurementHUD: MeasurementHUDState?

    // MARK: - Chart history (live measurements)
    @Published private(set) var heartRateHistory: [ChartPoint] = []
    @Published private(set) var oxygenHistory: [ChartPoint] = []
    @Published private(set) var bodyTemperatureHistory: [ChartPoint] = []
    @Published private(set) var ecgProgressHistory: [ChartPoint] = []
    /// Last ECG strip in millivolts (for live drawing; from SDK `filterSignals` + `convertToMv`).
    @Published private(set) var ecgWaveformMv: [Float] = []
    /// Instant heart rate from `muHearts` last value during ECG test, if provided.
    @Published private(set) var ecgLiveHeartRate: Int?
    @Published private(set) var syncProgressHistory: [ChartPoint] = []
    @Published private(set) var microProgressHistory: [ChartPoint] = []

    private var chartSeq = 0
    private let chartCap = 96

    /// Cancels if measurement finishes normally. Fires `abortStuckManualMeasurement()` if still on the same op.
    private var measurementTimeoutTask: Task<Void, Never>?
    private let defaultManualMeasurementSeconds: UInt64 = 30
    /// Some bands stop sending “Over” state but leave the app waiting — close HUD after this quiet period with a valid reading.
    private let liveReadingQuietFinishNanoseconds: UInt64 = 2_200_000_000

    private let bleService: BleService
    private var liveMeasurementDebounceTask: Task<Void, Never>?
    /// SpO₂: some bands send state `0` again when the user stops on the watch instead of `Over`.
    private var oxygenSawNonStartState = false
    /// Heart rate: same pattern as SpO₂ (`VPTestHeartStateStart` after testing).
    private var heartSawNonStartState = false
    private var isAutoHRPulseInFlight = false
    /// Used by `VPDataBaseOperation` step→distance/kcal conversion (must match band personal info).
    var userStatureCm: UInt = 175
    /// Last successful `veepooSdkStartReadDeviceAllData` finish (SDK local DB is filled from the band).
    private var lastDailySyncAt: Date?

    /// Only valid after `BleService.configureSDKIfNeeded()` — calling `shareVPPeripheralManager()` earlier can crash inside the SDK.
    private var manager: VPPeripheralBaseManage? {
        guard bleService.isSDKConfigured else { return nil }
        return VPPeripheralManage.shareVPPeripheralManager()
    }

    init(bleService: BleService) {
        self.bleService = bleService
    }

    var canRunManualTests: Bool {
        switch operation {
        case .idle:
            return true
        case .readingDailyData, .readingSteps, .readingSleep:
            return false
        default:
            return false
        }
    }

    var isMeasuringOrSyncing: Bool {
        measurementHUD != nil
    }

    var isConnected: Bool {
        guard bleService.isSDKConfigured else { return false }
        guard let central = VPBleCentralManage.sharedBleManager() else { return false }
        return central.isConnected
    }

    var supportsECG: Bool {
        (bleService.connectedDevice?.ecgType ?? 0) != 0
    }

    var supportsTemperature: Bool {
        (bleService.connectedDevice?.temperatureType ?? 0) != 0
    }

    var supportsMicroTest: Bool {
        (bleService.connectedDevice?.healthGlanceType ?? 0) == 1
    }

    func syncTime() {
        guardConnectedAndManager { manage in
            manage.veepooSDKSettingTime { [weak self] success in
                Task { @MainActor in
                    self?.lastError = success ? nil : L10n.Err.syncTime
                }
            }
        }
    }

    func syncPersonalInfo(height: Int, weight: Int, age: Int, sex: Int, targetStep: Int) {
        guardConnectedAndManager { manage in
            let info = VPSyncPersonalInfo()
            info.status = Int32(height)
            info.weight = Int32(weight)
            info.age = Int32(age)
            info.sex = Int32(sex)
            info.targetStep = Int32(targetStep)
            manage.veepooSDKSynchronousPersonalInformation(info) { [weak self] state in
                Task { @MainActor in
                    self?.lastError = state == 1 ? nil : L10n.Err.syncPersonal
                }
            }
        }
    }

    func setMetric(_ enabled: Bool) {
        setBaseFunction(rawType: 3, enabled: enabled)
    }

    func setTimeFormat24h(_ enabled: Bool) {
        setBaseFunction(rawType: 4, enabled: enabled)
    }

    func setAutoHR(_ enabled: Bool) {
        setBaseFunction(rawType: 5, enabled: enabled)
    }

    func setAutoTemperature(_ enabled: Bool) {
        setBaseFunction(rawType: 24, enabled: enabled)
    }

    /// After BLE shows “verified”, enable continuous HR on the band so health/SpO₂ commands work on many JL+Veepoo watches.
    func bootstrapHealthChannelAfterVerification() {
        guard isConnected else { return }
        syncTime()
        setAutoHR(true)
    }

    /// Same “kick” as toggling Auto HR — call before live measurements if the band was slow to open the health pipe.
    func ensureLiveMeasurementChannel() {
        guard isConnected else { return }
        setAutoHR(true)
    }

    /// Brief Auto-HR off→on to keep the health/SpO₂ pipe open on some bands. Restores `enabled` after ~200ms (matches Settings when passed from the view model).
    func pulseAutoHRHealthChannel(restoreTo enabled: Bool) {
        guard isConnected else { return }
        guard !isAutoHRPulseInFlight else { return }
        isAutoHRPulseInFlight = true
        setAutoHR(false)
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 200_000_000)
            if self.isConnected {
                self.setAutoHR(enabled)
            }
            self.isAutoHRPulseInFlight = false
        }
    }

    func readAllDailyData() {
        Task { _ = await pullDailyDataFromBand(showHUD: true) }
    }

    /// True when the band reports accurate sleep — Veepoo's full daily dump can crash in `VPAccurateSleepModel`.
    private var deviceUsesAccurateSleep: Bool {
        (bleService.connectedDevice?.sleepType ?? 0) != 0
    }

    /// `VPPeripheralManage` path: dump band → SDK DB.
    /// By default skipped on accurate-sleep bands (SDK can crash). Pass `forceDespiteAccurateSleep`
    /// only from explicit Activity sleep sync after the UI is already showing steps.
    @discardableResult
    func pullDailyDataFromBand(showHUD: Bool = true, forceDespiteAccurateSleep: Bool = false) async -> Bool {
        if deviceUsesAccurateSleep, !forceDespiteAccurateSleep {
            readProgressText = "daily dump skipped (accurate sleep band)"
            return false
        }

        await waitUntilOperationIdle(timeoutSeconds: 2)
        guard canStart(.readingDailyData) else { return false }
        // Do not poke AutoHR here — wiki forbids concurrent cmds while reading daily data.
        guard let mgr = manager else {
            lastError = L10n.Err.deviceNotConnected
            finishOperation()
            return false
        }

        syncProgressHistory.removeAll()
        if showHUD {
            measurementHUD = MeasurementHUDState(kind: .dailySync, progress01: 0.05)
        }
        scheduleManualMeasurementTimeout(for: .readingDailyData, seconds: 45)

        let startOK = TFTryObjC {
            mgr.veepooSdkStartReadDeviceAllData { [weak self] state, total, current, progress in
                Task { @MainActor in
                    guard let self else { return }
                    self.readProgressText = "state: \(state.rawValue), day \(current)/\(max(total, 1)), progress \(progress)%"
                    self.appendChart(Double(progress), to: &self.syncProgressHistory)
                    let p = Double(progress) / 100.0
                    if showHUD {
                        self.measurementHUD = MeasurementHUDState(kind: .dailySync, progress01: max(0.05, min(1, p)))
                    }
                    if state.rawValue == 2 {
                        self.lastDailySyncAt = Date()
                        self.finishOperation()
                    } else if state.rawValue == 0 || state.rawValue == 1 {
                        self.operation = .readingDailyData
                    }
                }
            }
        }

        guard startOK else {
            lastError = L10n.Err.opBusy
            finishOperation()
            return false
        }

        await waitUntilOperationIdle(timeoutSeconds: 45)
        if measurementHUD != nil, operation == .readingDailyData {
            finishOperation()
        }
        return lastDailySyncAt != nil || operation == .idle
    }

    func readTodaySteps() {
        Task { _ = await fetchTodayStepsSnapshot(showHUD: true) }
    }

    func readTodaySleep() {
        Task { _ = await fetchSleepMinutesSnapshot(showHUD: true) }
    }

    /// Load today’s steps from the Veepoo SDK local DB (filled by daily sync).
    @discardableResult
    func fetchTodayStepsSnapshot(showHUD: Bool = false, pullDailyIfNeeded: Bool = true) async -> Int? {
        if pullDailyIfNeeded {
            await ensureRecentDailySync(showHUD: showHUD)
        }
        if showHUD {
            measurementHUD = MeasurementHUDState(kind: .stepsSnapshot, progress01: nil)
        }

        await waitUntilOperationIdle(timeoutSeconds: 2)
        operation = .readingSteps
        defer { finishOperation() }

        if let steps = await loadStepsFromSDKDatabase(dayOffset: 0), steps >= 0 {
            todaySteps = steps
            return steps
        }
        // Last resort: AddManage-style API (often empty on VPPeripheralManage).
        if let steps = await readStepsViaDirectSDK(dayNumber: 0), steps >= 0 {
            todaySteps = steps
            return steps
        }
        return todaySteps
    }

    /// Load last-night sleep minutes from the SDK local DB.
    @discardableResult
    func fetchSleepMinutesSnapshot(showHUD: Bool = false, pullDailyIfNeeded: Bool = true) async -> Int? {
        if pullDailyIfNeeded {
            await ensureRecentDailySync(showHUD: showHUD)
        }
        if showHUD {
            measurementHUD = MeasurementHUDState(kind: .sleepSnapshot, progress01: nil)
        }

        await waitUntilOperationIdle(timeoutSeconds: 2)
        operation = .readingSleep
        defer { finishOperation() }

        // Veepoo: “today’s sleep” UI is usually yesterday’s night.
        if let minutes = loadSleepMinutesFromSDKDatabase(dayOffset: 1), minutes > 0 {
            todaySleepMinutes = minutes
            return minutes
        }
        if let minutes = loadSleepMinutesFromSDKDatabase(dayOffset: 0), minutes > 0 {
            todaySleepMinutes = minutes
            return minutes
        }
        if let minutes = await readSleepViaDirectSDK(dayNumber: 1), minutes > 0 {
            todaySleepMinutes = minutes
            return minutes
        }
        if let minutes = await readSleepViaDirectSDK(dayNumber: 0), minutes > 0 {
            todaySleepMinutes = minutes
            return minutes
        }
        return todaySleepMinutes
    }

    /// Wiki realtime step totals (`Step` / `Dis` / `Cal`) — matches the watch face, no daily dump required.
    struct BandDayTotals: Equatable {
        var steps: Int?
        var caloriesKcal: Double?
        var distanceKm: Double?
        var sleepMinutes: Int?
    }

    /// Official demo path: `VPDataBaseOperation.veepooSDKGetStepData` for today.
    @discardableResult
    func fetchRealtimeStepTotals() async -> BandDayTotals {
        applyStatureFromDeviceIfAvailable()
        var totals = BandDayTotals()
        guard let dict = await loadStepDictionaryFromSDKDatabase(dayOffset: 0) else {
            return totals
        }
        if let steps = Self.parseTotalSteps(from: dict) {
            todaySteps = steps
            totals.steps = steps
        }
        if let cal = Self.parseDouble(from: dict, keys: ["Cal", "cal", "CAL", "calorie", "calories"]) {
            todayCaloriesKcal = cal
            totals.caloriesKcal = cal
        }
        if let dis = Self.parseDouble(from: dict, keys: ["Dis", "dis", "DIS", "distance"]) {
            todayDistanceKm = dis
            totals.distanceKm = dis
        }
        return totals
    }

    /// Activity sync: realtime steps/kcal first, then robust sleep (band → DB → HealthKit).
    func syncActivityMetricsFromBand(includeSleep: Bool = true) async -> BandDayTotals {
        var totals = await fetchRealtimeStepTotals()
        guard includeSleep else { return totals }

        if let sleep = await fetchSleepMinutesRobust(), sleep > 0 {
            todaySleepMinutes = sleep
            totals.sleepMinutes = sleep
        }
        return totals
    }

    /// Multi-source sleep for “last night” (wiki: sleep day index starts at 1 = yesterday).
    @discardableResult
    func fetchSleepMinutesRobust() async -> Int? {
        // 1) Direct device read (works even before/without full daily dump on many bands).
        for day in [1, 2, 0] {
            if let minutes = await readSleepViaDirectSDK(dayNumber: day), minutes > 0 {
                todaySleepMinutes = minutes
                return minutes
            }
        }

        // 2) Ordinary sleep already in SDK DB.
        for dayOffset in [1, 0, 2] {
            if let minutes = loadSleepMinutesFromSDKDatabase(dayOffset: dayOffset), minutes > 0 {
                todaySleepMinutes = minutes
                return minutes
            }
        }

        // 3) Quiet daily dump — fills SDK DB. Skip on accurate-sleep bands (dump/parse can kill process).
        if !deviceUsesAccurateSleep {
            _ = await pullDailyDataFromBand(showHUD: false)
            for dayOffset in [1, 0, 2] {
                if let minutes = loadSleepMinutesFromSDKDatabase(dayOffset: dayOffset), minutes > 0 {
                    todaySleepMinutes = minutes
                    return minutes
                }
            }
        } else {
            // Accurate bands: never auto daily-dump (can kill process). Read accurate DB in @try only.
            for dayOffset in [1, 0, 2] {
                if let minutes = loadAccurateSleepMinutesSafely(dayOffset: dayOffset), minutes > 0 {
                    todaySleepMinutes = minutes
                    return minutes
                }
            }
            try? await Task.sleep(nanoseconds: 800_000_000)
            for day in [1, 2, 0] {
                if let minutes = await readSleepViaDirectSDK(dayNumber: day), minutes > 0 {
                    todaySleepMinutes = minutes
                    return minutes
                }
            }
        }

        // 4) Apple Health fallback (entitlement + permission required).
        if let hkSleep = await HealthKitWellnessService.fetchRecentSleepMinutes(), hkSleep > 0 {
            todaySleepMinutes = hkSleep
            return hkSleep
        }
        return todaySleepMinutes
    }

    /// Steps + sleep for Activity/Goals (legacy entry — prefers realtime steps).
    func syncStepsAndSleepFromBand(
        showHUD: Bool = false,
        pullDailyFirst: Bool = false
    ) async -> (steps: Int?, sleepMinutes: Int?) {
        _ = showHUD
        if pullDailyFirst, !deviceUsesAccurateSleep {
            _ = await pullDailyDataFromBand(showHUD: showHUD)
        }
        let totals = await syncActivityMetricsFromBand(includeSleep: true)
        return (totals.steps, totals.sleepMinutes)
    }

    private func applyStatureFromDeviceIfAvailable() {
        let deviceStature = bleService.connectedDevice?.deviceStature ?? 0
        if deviceStature > 0 {
            userStatureCm = deviceStature
        }
    }

    private func ensureRecentDailySync(showHUD: Bool) async {
        // Never auto-dump on accurate-sleep devices (connect crash).
        guard !deviceUsesAccurateSleep else { return }
        if let last = lastDailySyncAt, Date().timeIntervalSince(last) < 90 {
            return
        }
        _ = await pullDailyDataFromBand(showHUD: showHUD)
    }

    private var deviceTableID: String? {
        let mac = bleService.connectedDevice?.deviceAddress?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return mac.isEmpty ? nil : mac
    }

    /// Sync stored heart-rate only (no live test). Never runs AllData dump (HRV crash on accurate-sleep).
    /// Order: band basic-data packets → SDK local DB → half-hour averages.
    func syncAndFetchHeartSamples(dayCount: Int = 7) async -> (samples: [(date: Date, bpm: Double)], debug: String) {
        var notes: [String] = []
        let connected = isConnected && deviceTableID != nil
        guard connected else {
            return ([], "watch: not connected")
        }

        notes.append(deviceUsesAccurateSleep ? "band: accurateSleep" : "band: ordinary")
        notes.append("dump: skipped (avoid HRV hang/crash)")

        let days = max(1, min(dayCount, 14))
        let basic = await pullBasicHeartFromBand(dayCount: days)
        var samples = basic.samples
        notes.append(basic.debug)

        let origin = fetchOriginalHeartSamples(dayCount: days)
        notes.append("origin5m: \(origin.count)")
        samples = Self.mergeHeartSamples(samples, origin)

        if samples.isEmpty {
            let half = fetchHalfHourHeartSamples(dayCount: days)
            notes.append("halfHour: \(half.count)")
            samples = Self.mergeHeartSamples(samples, half)
        } else {
            notes.append("halfHour: skipped")
        }

        samples.sort { $0.date < $1.date }
        notes.append("total: \(samples.count)")
        let debug = notes.joined(separator: " · ")
        print("[PulseSync] \(debug)")
        return (samples, debug)
    }

    /// Pull 5‑min basic HR from the band via `veepooSDK_readBasicDataWithDayNumber` (no AllData / no HRV).
    /// Works when the Manage stack forwards AddManage-style reads; otherwise returns empty.
    func pullBasicHeartFromBand(dayCount: Int) async -> (samples: [(date: Date, bpm: Double)], debug: String) {
        await waitUntilOperationIdle(timeoutSeconds: 2)
        forceIdleForPulseIfNeeded()
        guard canStart(.readingDailyData) else {
            return ([], "basic: busy(\(lastError ?? "?"))")
        }
        cancelManualMeasurementTimeout()
        defer { finishOperation() }

        var all: [(date: Date, bpm: Double)] = []
        var dayNotes: [String] = []
        let days = max(1, min(dayCount, 14))

        for day in 0..<days {
            let daySamples = await readBasicHeartDay(dayNumber: day)
            dayNotes.append("d\(day)=\(daySamples.count)")
            all.append(contentsOf: daySamples)
            if daySamples.isEmpty, day >= 2 {
                // Older days often empty on this stack — stop early to keep sync snappy.
                break
            }
        }

        let debug = "basic: \(all.count)[\(dayNotes.joined(separator: ","))]"
        print("[PulseSync] \(debug)")
        return (all, debug)
    }

    private func readBasicHeartDay(dayNumber: Int) async -> [(date: Date, bpm: Double)] {
        guard let mgr = manager, isConnected else { return [] }
        let cal = Calendar.current
        let dayStart = cal.date(byAdding: .day, value: -dayNumber, to: cal.startOfDay(for: Date()))
            ?? cal.startOfDay(for: Date())

        return await withCheckedContinuation { (cont: CheckedContinuation<[(Date, Double)], Never>) in
            var resumed = false
            var collected: [(Date, Double)] = []
            var lastPackage = 0

            let finish: () -> Void = {
                guard !resumed else { return }
                resumed = true
                cont.resume(returning: collected)
            }

            let ok = TFTryObjC {
                mgr.veepooSDK_readBasicData(withDayNumber: dayNumber, maxPackage: 1) { array, totalPackage, currentReadPackage in
                    Task { @MainActor in
                        lastPackage = max(lastPackage, Int(currentReadPackage))
                        let items: [Any]
                        if let arr = array as [Any]? {
                            items = arr
                        } else if let arr = array as NSArray? {
                            items = arr.map { $0 as Any }
                        } else {
                            items = []
                        }
                        collected.append(contentsOf: Self.parseBasicHeartArray(items, dayStart: dayStart))
                        let total = max(Int(totalPackage), 1)
                        let current = Int(currentReadPackage)
                        if current >= total || totalPackage == 0 {
                            finish()
                        }
                    }
                }
            }
            if !ok {
                finish()
                return
            }
            Task {
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                finish()
            }
        }
    }

    private static func parseBasicHeartArray(_ array: [Any], dayStart: Date) -> [(date: Date, bpm: Double)] {
        let cal = Calendar.current
        var out: [(Date, Double)] = []
        for item in array {
            let dict: [String: Any]
            if let d = item as? [String: Any] {
                dict = d
            } else if let d = item as? NSDictionary {
                var mapped: [String: Any] = [:]
                for (k, v) in d {
                    mapped[String(describing: k)] = v
                }
                dict = mapped
            } else {
                continue
            }

            guard let bpm = heartValue(from: dict), bpm >= 30, bpm <= 250 else { continue }

            let timeRaw = dict["time"] ?? dict["Time"] ?? dict["date"] ?? dict["Date"]
            let timeKey = timeRaw.map { String(describing: $0) } ?? ""
            let parts = timeKey
                .replacingOccurrences(of: "-", with: ":")
                .split(whereSeparator: { $0 == ":" || $0 == " " })
                .map(String.init)
            var hour = 0
            var minute = 0
            if parts.count >= 2, let h = Int(parts[parts.count - 2]), let m = Int(parts[parts.count - 1]) {
                hour = h
                minute = m
            } else if let idx = dict["timeIndex"] as? Int {
                // Some firmwares use 5‑min slot index from midnight.
                hour = (idx * 5) / 60
                minute = (idx * 5) % 60
            }

            var comps = cal.dateComponents([.year, .month, .day], from: dayStart)
            comps.hour = min(max(hour, 0), 23)
            comps.minute = min(max(minute, 0), 59)
            guard let date = cal.date(from: comps) else { continue }
            out.append((date, bpm))
        }
        return out
    }

    private static func mergeHeartSamples(
        _ a: [(date: Date, bpm: Double)],
        _ b: [(date: Date, bpm: Double)]
    ) -> [(date: Date, bpm: Double)] {
        var out = a
        for sample in b {
            let dup = out.contains {
                abs($0.bpm - sample.bpm) < 0.6 && abs($0.date.timeIntervalSince(sample.date)) < 90
            }
            if !dup { out.append(sample) }
        }
        return out
    }

    /// Clear a stuck BLE op so Pulse measure/sync can start again.
    func forceIdleForPulseIfNeeded() {
        guard operation != .idle else { return }
        print("[PulseSync] forceIdle from \(operation.rawValue)")
        cancelManualMeasurementTimeout()
        liveMeasurementDebounceTask?.cancel()
        finishOperation()
    }

    /// Explicit user-initiated HR test for «Измерить пульс» (not used by «Обновить данные»).
    /// Wear the watch snugly; returns nil on timeout / not worn / busy.
    func captureLiveHeartSample(timeoutSeconds: Double = 25) async -> (date: Date, bpm: Double)? {
        await waitUntilOperationIdle(timeoutSeconds: 3)
        forceIdleForPulseIfNeeded()
        // Sensor cooldown after a previous test / on-watch measure.
        try? await Task.sleep(nanoseconds: 1_200_000_000)

        guard canStart(.heartTest, needsManualFreeState: true) else {
            print("[PulseSync] measure blocked: \(lastError ?? "busy")")
            return nil
        }
        ensureLiveMeasurementChannel()
        heartSawNonStartState = false
        // Do not set measurementHUD — Pulse has its own overlay.
        cancelManualMeasurementTimeout()

        let result: Int? = await withCheckedContinuation { (cont: CheckedContinuation<Int?, Never>) in
            var resumed = false
            var best: Int?
            var settleTask: Task<Void, Never>?

            let finish: (Int?) -> Void = { [weak self] value in
                guard let self else {
                    if !resumed {
                        resumed = true
                        cont.resume(returning: value)
                    }
                    return
                }
                guard !resumed else { return }
                resumed = true
                settleTask?.cancel()
                self.manager?.veepooSDKTestHeartStart(false) { [weak self] _, _ in
                    Task { @MainActor in self?.finishOperation() }
                }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 800_000_000)
                    if self.operation == .heartTest {
                        self.finishOperation()
                    }
                }
                cont.resume(returning: value)
            }

            manager?.veepooSDKTestHeartStart(true) { [weak self] state, value in
                Task { @MainActor in
                    guard let self else { return }
                    guard self.operation == .heartTest else { return }
                    let v = Int(value)
                    self.heartRate = HeartRateReading(state: state, value: v)
                    if state.rawValue != 0 { self.heartSawNonStartState = true }
                    if v >= 40, v <= 220 {
                        best = v
                        if state.rawValue == 1, settleTask == nil {
                            settleTask = Task { @MainActor in
                                try? await Task.sleep(nanoseconds: 4_000_000_000)
                                finish(best)
                            }
                        }
                    }
                    // Terminal only — do NOT finish on state 0 (that aborted retries).
                    if state.rawValue == 2 || state.rawValue == 3 || state.rawValue == 4 {
                        finish(best)
                    }
                }
            }

            Task { @MainActor in
                try? await Task.sleep(nanoseconds: UInt64(timeoutSeconds * 1_000_000_000))
                finish(best)
            }
        }

        guard let bpm = result, bpm >= 40, bpm <= 220 else { return nil }
        return (Date(), Double(bpm))
    }

    /// 5‑minute original HR from Veepoo local DB (filled by daily dump).
    func fetchOriginalHeartSamples(dayCount: Int = 7) -> [(date: Date, bpm: Double)] {
        parseHeartDictSamples(dayCount: dayCount) { dateStr, tableID in
            var dict: NSDictionary?
            _ = TFTryObjC {
                if let raw = VPDataBaseOperation.veepooSDKGetOriginalData(
                    withDate: dateStr,
                    andTableID: tableID
                ) as NSDictionary? {
                    dict = raw
                } else if let raw = VPDataBaseOperation.veepooSDKGetOriginalData(
                    withDate: dateStr,
                    andTableID: tableID
                ) as? [AnyHashable: Any] {
                    dict = raw as NSDictionary
                }
            }
            return dict
        }
    }

    /// Half-hour average heart-rate samples from the Veepoo local DB.
    func fetchHalfHourHeartSamples(dayCount: Int = 7) -> [(date: Date, bpm: Double)] {
        parseHeartDictSamples(dayCount: dayCount) { dateStr, tableID in
            var dict: NSDictionary?
            _ = TFTryObjC {
                if let raw = VPDataBaseOperation.veepooSDKGetOriginalChangeHalfHourData(
                    withDate: dateStr,
                    andTableID: tableID
                ) as NSDictionary? {
                    dict = raw
                } else if let raw = VPDataBaseOperation.veepooSDKGetOriginalChangeHalfHourData(
                    withDate: dateStr,
                    andTableID: tableID
                ) as? [AnyHashable: Any] {
                    dict = raw as NSDictionary
                }
            }
            return dict
        }
    }

    private func parseHeartDictSamples(
        dayCount: Int,
        loader: (_ dateStr: String, _ tableID: String) -> NSDictionary?
    ) -> [(date: Date, bpm: Double)] {
        guard let tableID = deviceTableID else { return [] }
        let cal = Calendar.current
        var out: [(Date, Double)] = []
        let days = max(1, min(dayCount, 30))

        for offset in 0..<days {
            let dateStr = Self.sdkDateString(dayOffset: offset)
            guard let dict = loader(dateStr, tableID) else { continue }
            let dayStart = cal.date(byAdding: .day, value: -offset, to: cal.startOfDay(for: Date()))
                ?? cal.startOfDay(for: Date())

            for (key, value) in dict {
                let timeKey = String(describing: key)
                let parts = timeKey.split(separator: ":").map(String.init)
                guard parts.count >= 2,
                      let hour = Int(parts[0]),
                      let minute = Int(parts[1])
                else { continue }

                guard let bpm = Self.heartValue(from: value), bpm >= 30, bpm <= 250 else { continue }

                var comps = cal.dateComponents([.year, .month, .day], from: dayStart)
                comps.hour = hour
                comps.minute = minute
                guard let date = cal.date(from: comps) else { continue }
                out.append((date, bpm))
            }
        }
        return out.sorted { $0.0 < $1.0 }
    }

    /// Prefer `heartValue`; else average of `ppgs` / `ecgs` arrays when present.
    private static func heartValue(from value: Any) -> Double? {
        let nested: [AnyHashable: Any]?
        if let d = value as? [AnyHashable: Any] {
            nested = d
        } else if let d = value as? NSDictionary {
            nested = d as? [AnyHashable: Any]
        } else {
            return doubleValue(value)
        }
        guard let nested else { return nil }

        if let bpm = doubleValue(nested["heartValue"] ?? nested["HeartValue"]), bpm >= 30 {
            return bpm
        }
        for key in ["ppgs", "ecgs", "PPGs", "ECGs"] {
            if let arr = nested[key] as? [Any] {
                let vals = arr.compactMap(doubleValue).filter { $0 >= 30 && $0 <= 250 }
                if !vals.isEmpty {
                    return vals.reduce(0, +) / Double(vals.count)
                }
            } else if let arr = nested[key] as? NSArray {
                let vals = arr.compactMap { doubleValue($0) }.filter { $0 >= 30 && $0 <= 250 }
                if !vals.isEmpty {
                    return vals.reduce(0, +) / Double(vals.count)
                }
            }
        }
        return nil
    }

    private static func doubleValue(_ any: Any?) -> Double? {
        if let d = any as? Double { return d }
        if let n = any as? NSNumber { return n.doubleValue }
        if let s = any as? String { return Double(s) }
        return nil
    }

    private static func sdkDateString(dayOffset: Int, from date: Date = Date()) -> String {
        let cal = Calendar.current
        let day = cal.date(byAdding: .day, value: -dayOffset, to: cal.startOfDay(for: date)) ?? date
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = cal.timeZone
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: day)
    }

    private func loadStepsFromSDKDatabase(dayOffset: Int) async -> Int? {
        Self.parseTotalSteps(from: await loadStepDictionaryFromSDKDatabase(dayOffset: dayOffset))
    }

    private func loadStepDictionaryFromSDKDatabase(dayOffset: Int) async -> NSDictionary? {
        guard let tableID = deviceTableID else { return nil }
        applyStatureFromDeviceIfAvailable()
        let dateStr = Self.sdkDateString(dayOffset: dayOffset)
        let stature = userStatureCm

        return await withCheckedContinuation { (cont: CheckedContinuation<NSDictionary?, Never>) in
            var resumed = false
            let finish: (NSDictionary?) -> Void = { value in
                guard !resumed else { return }
                resumed = true
                cont.resume(returning: value)
            }
            let ok = TFTryObjC {
                VPDataBaseOperation.veepooSDKGetStepData(
                    withDate: dateStr,
                    andTableID: tableID,
                    changeUserStature: stature
                ) { stepDict in
                    if let d = stepDict as NSDictionary? {
                        finish(d)
                    } else if let d = stepDict as? [AnyHashable: Any] {
                        finish(d as NSDictionary)
                    } else {
                        finish(nil)
                    }
                }
            }
            if !ok {
                finish(nil)
                return
            }
            Task {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                finish(nil)
            }
        }
    }

    private func loadSleepMinutesFromSDKDatabase(dayOffset: Int) -> Int? {
        guard let tableID = deviceTableID else { return nil }
        let dateStr = Self.sdkDateString(dayOffset: dayOffset)

        var segments: [Any] = []
        _ = TFTryObjC {
            if let arr = VPDataBaseOperation.veepooSDKGetSleepData(
                withDate: dateStr,
                andTableID: tableID
            ) as? NSArray, arr.count > 0 {
                segments = arr.map { $0 as Any }
            }
        }

        sleepSegmentsToday = segments.count
        return Self.parseSleepMinutes(from: segments)
    }

    /// Accurate-sleep DB read — always inside TFTryObjC (SDK can throw NSCFString year).
    private func loadAccurateSleepMinutesSafely(dayOffset: Int) -> Int? {
        guard let tableID = deviceTableID else { return nil }
        let dateStr = Self.sdkDateString(dayOffset: dayOffset)
        var minutes: Int?
        _ = TFTryObjC {
            let raw = VPDataBaseOperation.veepooSDKGetAccurateSleepData(
                withDate: dateStr,
                andTableID: tableID
            )
            let arr: [Any]
            if let a = raw as? [Any] {
                arr = a
            } else if let a = raw as? NSArray {
                arr = a.map { $0 as Any }
            } else {
                arr = []
            }
            if !arr.isEmpty {
                minutes = Self.parseSleepMinutes(from: arr)
            }
        }
        if let minutes, minutes > 0 {
            sleepSegmentsToday = max(sleepSegmentsToday ?? 0, 1)
        }
        return minutes
    }

    private func readStepsViaDirectSDK(dayNumber: Int) async -> Int? {
        await waitUntilOperationIdle(timeoutSeconds: 1)
        guard let mgr = manager, isConnected else { return nil }
        return await withCheckedContinuation { (cont: CheckedContinuation<Int?, Never>) in
            var resumed = false
            let finish: (Int?) -> Void = { value in
                guard !resumed else { return }
                resumed = true
                cont.resume(returning: value)
            }
            mgr.veepooSDK_readStepData(withDayNumber: dayNumber, result: { stepDict in
                finish(Self.parseTotalSteps(from: stepDict))
            })
            Task {
                try? await Task.sleep(nanoseconds: 6_000_000_000)
                finish(nil)
            }
        }
    }

    private func readSleepViaDirectSDK(dayNumber: Int) async -> Int? {
        await waitUntilOperationIdle(timeoutSeconds: 1)
        guard let mgr = manager, isConnected else { return nil }
        return await withCheckedContinuation { (cont: CheckedContinuation<Int?, Never>) in
            var resumed = false
            let finish: (Int?) -> Void = { value in
                guard !resumed else { return }
                resumed = true
                cont.resume(returning: value)
            }
            let started = TFTryObjC {
                mgr.veepooSDK_readSleepData(withDayNumber: dayNumber, result: { sleepOneDayArray in
                    var minutes: Int?
                    _ = TFTryObjC {
                        let arr: [Any] = ((sleepOneDayArray as NSArray?) ?? []).map { $0 as Any }
                        minutes = Self.parseSleepMinutes(from: arr)
                    }
                    finish(minutes)
                })
            }
            if !started {
                finish(nil)
                return
            }
            Task {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                finish(nil)
            }
        }
    }

    func startHeartTest() {
        guard canStart(.heartTest, needsManualFreeState: true) else { return }
        heartSawNonStartState = false
        ensureLiveMeasurementChannel()
        heartRateHistory.removeAll()
        measurementHUD = MeasurementHUDState(kind: .heart, progress01: nil)
        scheduleManualMeasurementTimeout(for: .heartTest, seconds: defaultManualMeasurementSeconds)
        manager?.veepooSDKTestHeartStart(true) { [weak self] state, value in
            Task { @MainActor in
                guard let self else { return }
                self.heartRate = HeartRateReading(state: state, value: Int(value))
                if state.rawValue == 0, self.heartSawNonStartState {
                    self.finishOperation()
                    return
                }
                if state.rawValue != 0 {
                    self.heartSawNonStartState = true
                }
                if value > 0 {
                    self.appendChart(Double(value), to: &self.heartRateHistory)
                }
                if state.rawValue == 1 {
                    self.measurementHUD = MeasurementHUDState(kind: .heart, progress01: nil)
                    let v = Int(value)
                    if v >= 40, v <= 220 {
                        self.scheduleQuietFinishForLiveMeasurement(expected: .heartTest)
                    }
                }
                if state.rawValue == 2 || state.rawValue == 3 || state.rawValue == 4 {
                    self.finishOperation()
                }
            }
        }
    }

    func stopHeartTest() {
        manager?.veepooSDKTestHeartStart(false) { [weak self] _, _ in
            Task { @MainActor in self?.finishOperation() }
        }
    }

    func startOxygenTest() {
        guard canStart(.oxygenTest, needsManualFreeState: true) else { return }
        oxygenSawNonStartState = false
        ensureLiveMeasurementChannel()
        oxygenHistory.removeAll()
        measurementHUD = MeasurementHUDState(kind: .oxygen, progress01: nil)
        scheduleManualMeasurementTimeout(for: .oxygenTest, seconds: defaultManualMeasurementSeconds)
        manager?.veepooSDKTestOxygenStart(true) { [weak self] state, value in
            Task { @MainActor in
                guard let self else { return }
                self.oxygen = OxygenReading(state: state, value: Int(value))
                // Watch stopped / idle: often only `Start(0)` is sent again — close HUD like pulse tab does.
                if state.rawValue == 0, self.oxygenSawNonStartState {
                    self.finishOperation()
                    return
                }
                if state.rawValue != 0 {
                    self.oxygenSawNonStartState = true
                }
                if state.rawValue == 1, value > 0, value <= 100 {
                    self.appendChart(Double(value), to: &self.oxygenHistory)
                }
                // 6 = calibration (value is progress), 7 = calibration done — keep session alive.
                if state.rawValue == 6 {
                    let p = min(1, max(0.08, Double(value) / 100.0))
                    self.measurementHUD = MeasurementHUDState(kind: .oxygen, progress01: p)
                    if value >= 95 {
                        self.scheduleQuietFinishForLiveMeasurement(expected: .oxygenTest)
                    }
                } else if state.rawValue == 7 {
                    self.measurementHUD = MeasurementHUDState(kind: .oxygen, progress01: 0.92)
                    self.scheduleQuietFinishForLiveMeasurement(expected: .oxygenTest)
                } else if state.rawValue == 1 {
                    self.measurementHUD = MeasurementHUDState(kind: .oxygen, progress01: nil)
                    let v = Int(value)
                    if v >= 60, v <= 100 {
                        self.scheduleQuietFinishForLiveMeasurement(expected: .oxygenTest)
                    }
                } else if state.rawValue == 0 {
                    self.measurementHUD = MeasurementHUDState(kind: .oxygen, progress01: nil)
                }
                if state.rawValue == 2 || state.rawValue == 3 || state.rawValue == 4 || state.rawValue == 5 || state.rawValue == 8 {
                    self.finishOperation()
                }
            }
        }
    }

    func stopOxygenTest() {
        manager?.veepooSDKTestOxygenStart(false) { [weak self] _, _ in
            Task { @MainActor in self?.finishOperation() }
        }
    }

    func startTemperatureTest() {
        guard supportsTemperature else {
            lastError = L10n.Err.tempUnsupported
            return
        }
        guard canStart(.temperatureTest, needsManualFreeState: true) else { return }
        ensureLiveMeasurementChannel()
        bodyTemperatureHistory.removeAll()
        measurementHUD = MeasurementHUDState(kind: .temperature, progress01: 0.05)
        scheduleManualMeasurementTimeout(for: .temperatureTest, seconds: defaultManualMeasurementSeconds)
        manager?.veepooSDK_temperatureTestStart(true, result: { [weak self] state, enable, progress, temp, originalTemp in
            Task { @MainActor in
                guard let self else { return }
                self.temperature = TemperatureReading(
                    state: state,
                    enable: enable,
                    progress: progress,
                    bodyTemperature: Double(temp) / 10.0,
                    skinTemperature: Double(originalTemp) / 10.0
                )
                let body = Double(temp) / 10.0
                if body > 30, body < 45 {
                    self.appendChart(body, to: &self.bodyTemperatureHistory)
                }
                let p = min(1, max(0, Double(progress) / 100.0))
                self.measurementHUD = MeasurementHUDState(kind: .temperature, progress01: max(0.05, p))
                if body > 30, body < 45, progress >= 90 {
                    self.scheduleQuietFinishForLiveMeasurement(expected: .temperatureTest)
                }
                if state.rawValue == 2 || state.rawValue == 9 || state.rawValue == 0 {
                    self.finishOperation()
                }
            }
        })
    }

    func stopTemperatureTest() {
        manager?.veepooSDK_temperatureTestStart(false, result: { [weak self] _, _, _, _, _ in
            Task { @MainActor in self?.finishOperation() }
        })
    }

    func startECGTest() {
        guard supportsECG else {
            lastError = L10n.Err.ecgUnsupported
            return
        }
        guard canStart(.ecgTest, needsManualFreeState: true) else { return }
        ensureLiveMeasurementChannel()
        ecgProgressHistory.removeAll()
        ecgWaveformMv.removeAll()
        ecgLiveHeartRate = nil
        measurementHUD = MeasurementHUDState(kind: .ecg, progress01: 0.05)
        scheduleManualMeasurementTimeout(for: .ecgTest, seconds: defaultManualMeasurementSeconds)
        manager?.veepooSDKTestECGStart(true) { [weak self] state, progress, model in
            Task { @MainActor in
                guard let self else { return }
                // `filterSignals` can be nil while bridged as non-optional → avoid implicit unwrap crash.
                let count = Self.safeECGFilterSignalCount(model)
                let p = Self.clampECGProgress(progress)
                self.ecg = ECGReading(state: state, progress: p, sampleCount: count)
                let mv = Self.ecgWaveformMillivolts(from: model)
                self.ecgWaveformMv = Self.downsampleECG(mv, maxPoints: 1_600)
                if let hr = Self.ecgLiveHeartRate(from: model) {
                    self.ecgLiveHeartRate = hr
                }
                self.appendChart(Double(p), to: &self.ecgProgressHistory)
                let frac = min(1, max(0.05, Double(p) / 100.0))
                self.measurementHUD = MeasurementHUDState(kind: .ecg, progress01: frac)
                if p >= 92 {
                    self.scheduleQuietFinishForLiveMeasurement(expected: .ecgTest)
                }
                if state.rawValue == 4 || state.rawValue == 5 || state.rawValue == 6 || state.rawValue == 2 || state.rawValue == 3 || state.rawValue == 7 {
                    self.finishOperation()
                }
            }
        }
    }

    func stopECGTest() {
        manager?.veepooSDKTestECGStart(false) { [weak self] _, _, _ in
            Task { @MainActor in self?.finishOperation() }
        }
    }

    func startMicroTest() {
        guard supportsMicroTest else {
            lastError = L10n.Err.microUnsupported
            return
        }
        guard canStart(.microTest, needsManualFreeState: true) else { return }
        ensureLiveMeasurementChannel()
        microProgressHistory.removeAll()
        measurementHUD = MeasurementHUDState(kind: .micro, progress01: 0.05)
        scheduleManualMeasurementTimeout(for: .microTest, seconds: defaultManualMeasurementSeconds)
        manager?.veepooSDKMicroTestOpenState(
            true,
            andProgress: { [weak self] progress in
                Task { @MainActor in
                    guard let self else { return }
                    self.microTest = MicroTestReading(progress: Int(progress), model: self.microTest?.model)
                    self.appendChart(Double(progress), to: &self.microProgressHistory)
                    let frac = min(1, max(0.05, Double(progress) / 100.0))
                    self.measurementHUD = MeasurementHUDState(kind: .micro, progress01: frac)
                    if progress >= 95 {
                        self.scheduleQuietFinishForLiveMeasurement(expected: .microTest)
                    }
                }
            },
            andFail: { [weak self] error in
                Task { @MainActor in
                    self?.lastError = (error as NSError?)?.localizedDescription ?? "Micro test failed."
                    self?.finishOperation()
                }
            },
            andSuccess: { [weak self] _, model in
                Task { @MainActor in
                    self?.microTest = MicroTestReading(progress: 100, model: model)
                    self?.finishOperation()
                }
            },
            andHeartRate: { _ in },
            andPPG: { _ in }
        )
    }

    func stopMicroTest() {
        manager?.veepooSDKMicroTestOpenState(
            false,
            andProgress: { _ in },
            andFail: { _ in },
            andSuccess: { [weak self] _, _ in
                Task { @MainActor in self?.finishOperation() }
            },
            andHeartRate: { _ in },
            andPPG: { _ in }
        )
    }

    func startBloodPressureTest() {
        guard canStart(.bloodPressureTest, needsManualFreeState: true) else { return }
        ensureLiveMeasurementChannel()
        measurementHUD = MeasurementHUDState(kind: .bloodPressure, progress01: 0.08)
        scheduleManualMeasurementTimeout(for: .bloodPressureTest, seconds: defaultManualMeasurementSeconds)
        manager?.veepooSDKTestBloodStart(true, testMode: 0) { [weak self] testState, testProgress, highBlood, lowBlood in
            Task { @MainActor in
                guard let self else { return }
                self.bloodPressure = BloodPressureReading(
                    state: testState,
                    progress: Int(testProgress),
                    systolic: Int(highBlood),
                    diastolic: Int(lowBlood)
                )
                let frac = min(1, max(0.08, Double(testProgress) / 100.0))
                self.measurementHUD = MeasurementHUDState(kind: .bloodPressure, progress01: frac)
                if testProgress >= 95 {
                    self.scheduleQuietFinishForLiveMeasurement(expected: .bloodPressureTest)
                }
                // VPTestBloodStateTesting = 0 — keep measuring; any other state ends the session.
                if testState.rawValue != 0 {
                    self.finishOperation()
                }
            }
        }
    }

    func stopBloodPressureTest() {
        manager?.veepooSDKTestBloodStart(false, testMode: 0) { [weak self] _, _, _, _ in
            Task { @MainActor in self?.finishOperation() }
        }
    }

    func startBloodGlucoseTest() {
        guard canStart(.bloodGlucoseTest, needsManualFreeState: true) else { return }
        ensureLiveMeasurementChannel()
        measurementHUD = MeasurementHUDState(kind: .bloodGlucose, progress01: nil)
        scheduleManualMeasurementTimeout(for: .bloodGlucoseTest, seconds: defaultManualMeasurementSeconds)
        manager?.veepooSDKTestBloodGlucoseStart(true, isPersonalModel: false) { [weak self] testState, testProgress, value, _ in
            Task { @MainActor in
                guard let self else { return }
                self.bloodGlucose = BloodGlucoseReading(state: testState, progress: Int(testProgress), valueRaw: value)
                let frac = min(1, max(0.08, Double(testProgress) / 100.0))
                // VPDeviceBloodGlucoseTestStateOpen = 1 — in progress; stay on overlay until a terminal state.
                if testState.rawValue == 1 {
                    self.measurementHUD = MeasurementHUDState(
                        kind: .bloodGlucose,
                        progress01: testProgress > 0 ? frac : nil
                    )
                    if testProgress >= 90, value > 0 {
                        self.scheduleQuietFinishForLiveMeasurement(expected: .bloodGlucoseTest)
                    }
                } else {
                    self.measurementHUD = MeasurementHUDState(kind: .bloodGlucose, progress01: frac)
                }
                if testState.rawValue != 1 {
                    self.finishOperation()
                }
            }
        }
    }

    func stopBloodGlucoseTest() {
        manager?.veepooSDKTestBloodGlucoseStart(false, isPersonalModel: false) { [weak self] _, _, _, _ in
            Task { @MainActor in self?.finishOperation() }
        }
    }

    private func setBaseFunction(rawType: Int, enabled: Bool) {
        guardConnectedAndManager { manage in
            guard let type = VPSettingBaseFunctionSwitchType(rawValue: rawType) else {
                self.lastError = L10n.Err.settingMap
                return
            }
            guard let state = VPSettingFunctionState(rawValue: enabled ? 1 : 2) else {
                self.lastError = L10n.Err.settingState
                return
            }
            manage.veepooSDKSettingBaseFunctionType(type, settingState: state) { [weak self] complete in
                Task { @MainActor in
                    if complete.rawValue == 3 || complete.rawValue == 0 {
                        self?.lastError = L10n.Err.settingFailed
                    } else {
                        self?.lastError = nil
                    }
                }
            }
        }
    }

    private func canStart(_ op: BleOperation, needsManualFreeState: Bool = false) -> Bool {
        guard isConnected else {
            lastError = L10n.Err.deviceNotConnected
            return false
        }
        if needsManualFreeState && operation == .readingDailyData {
            lastError = L10n.Err.dailyBusy
            return false
        }
        if operation != .idle {
            lastError = L10n.Err.opBusy
            return false
        }
        operation = op
        lastError = nil
        return true
    }

    private func guardConnectedAndManager(_ body: (VPPeripheralBaseManage) -> Void) {
        guard isConnected, let manage = manager else {
            lastError = L10n.Err.deviceNotConnected
            return
        }
        body(manage)
    }

    private func finishOperation() {
        cancelManualMeasurementTimeout()
        cancelLiveMeasurementDebounce()
        operation = .idle
        measurementHUD = nil
    }

    private func cancelLiveMeasurementDebounce() {
        liveMeasurementDebounceTask?.cancel()
        liveMeasurementDebounceTask = nil
    }

    /// If the band keeps sending “testing” but never sends Over/Complete, hide the overlay after readings go quiet.
    private func scheduleQuietFinishForLiveMeasurement(expected: BleOperation) {
        liveMeasurementDebounceTask?.cancel()
        liveMeasurementDebounceTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: liveReadingQuietFinishNanoseconds)
            } catch {
                return
            }
            await MainActor.run {
                guard let self else { return }
                guard self.operation == expected else { return }
                self.finishOperation()
            }
        }
    }

    /// For `readAllDailyData` — await until idle or timeout (used by pull-to-refresh / launch).
    func waitUntilOperationIdle(timeoutSeconds: Double) async {
        let deadline = Date().addingTimeInterval(timeoutSeconds)
        while operation != .idle, Date() < deadline {
            try? await Task.sleep(nanoseconds: 200_000_000)
        }
    }

    private func scheduleManualMeasurementTimeout(for expected: BleOperation, seconds: UInt64) {
        measurementTimeoutTask?.cancel()
        measurementTimeoutTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: seconds * 1_000_000_000)
            } catch {
                return
            }
            await MainActor.run {
                guard let self else { return }
                guard self.operation == expected else { return }
                self.lastError = L10n.Err.measurementTimeout
                self.abortStuckManualMeasurement()
            }
        }
    }

    private func cancelManualMeasurementTimeout() {
        measurementTimeoutTask?.cancel()
        measurementTimeoutTask = nil
    }

    /// User tapped the ✕ — clear HUD **immediately** (Veepoo stop calls can block the main thread and freeze the UI).
    func dismissMeasurementOverlay() {
        let opToStop = operation
        finishOperation()
        guard opToStop != .idle else { return }
        DispatchQueue.main.async { [weak self] in
            guard let self, let mgr = self.manager, self.isConnected else { return }
            self.sendSDKStopCommands(for: opToStop, manager: mgr)
        }
    }

    /// Force-stop the current manual read/test if the SDK never answers (timeout).
    private func abortStuckManualMeasurement() {
        cancelManualMeasurementTimeout()
        cancelLiveMeasurementDebounce()
        if let mgr = manager {
            sendSDKStopCommands(for: operation, manager: mgr)
        }
        operation = .idle
        measurementHUD = nil
    }

    private func sendSDKStopCommands(for op: BleOperation, manager mgr: VPPeripheralBaseManage) {
        switch op {
        case .heartTest:
            mgr.veepooSDKTestHeartStart(false) { _, _ in }
        case .oxygenTest:
            mgr.veepooSDKTestOxygenStart(false) { _, _ in }
        case .temperatureTest:
            mgr.veepooSDK_temperatureTestStart(false, result: { _, _, _, _, _ in })
        case .ecgTest:
            mgr.veepooSDKTestECGStart(false) { _, _, _ in }
        case .microTest:
            mgr.veepooSDKMicroTestOpenState(
                false,
                andProgress: { _ in },
                andFail: { _ in },
                andSuccess: { _, _ in },
                andHeartRate: { _ in },
                andPPG: { _ in }
            )
        case .bloodPressureTest:
            mgr.veepooSDKTestBloodStart(false, testMode: 0) { _, _, _, _ in }
        case .bloodGlucoseTest:
            mgr.veepooSDKTestBloodGlucoseStart(false, isPersonalModel: false) { _, _, _, _ in }
        case .readingSteps, .readingSleep, .readingDailyData, .idle:
            break
        }
    }

    private static func parseTotalSteps(from dict: Any?) -> Int? {
        guard let n = parseDouble(
            from: dict,
            keys: [
                "Step", "totalStep", "step", "steps", "TotalStep",
                "stepValue", "value", "stepTotal", "StepValue"
            ]
        ) else { return nil }
        return max(0, Int(n.rounded()))
    }

    private static func parseDouble(from dict: Any?, keys: [String]) -> Double? {
        guard let dict else { return nil }
        if let d = dict as? NSDictionary {
            for k in keys {
                if let n = d.object(forKey: k) as? NSNumber { return n.doubleValue }
                if let s = d.object(forKey: k) as? String,
                   let v = Double(s.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: ",", with: ".")) {
                    return v
                }
            }
            return nil
        }
        if let d = dict as? [AnyHashable: Any] {
            for k in keys {
                if let n = d[k] as? NSNumber { return n.doubleValue }
                if let n = d[k] as? Double { return n }
                if let n = d[k] as? Int { return Double(n) }
                if let s = d[k] as? String,
                   let v = Double(s.trimmingCharacters(in: .whitespacesAndNewlines)
                    .replacingOccurrences(of: ",", with: ".")) {
                    return v
                }
            }
        }
        return nil
    }

    /// Sums ordinary sleep dicts (`SLE_HOUR`/`SLE_MINUTE`) and accurate-sleep objects (`sleepDuration` via KVC).
    private static func parseSleepMinutes(from segments: [Any]) -> Int? {
        guard !segments.isEmpty else { return nil }
        var total = 0
        var sawValue = false

        for item in segments {
            if let obj = item as? NSObject,
               !(obj is NSDictionary),
               !(item is [AnyHashable: Any]) {
                if let m = intFromAny(obj.value(forKey: "sleepDuration")), m > 0 {
                    total += m
                    sawValue = true
                    continue
                }
                let deep = intFromAny(obj.value(forKey: "deepDuration")) ?? 0
                let light = intFromAny(obj.value(forKey: "lightDuration")) ?? 0
                let other = intFromAny(obj.value(forKey: "otherDuration")) ?? 0
                let sum = deep + light + other
                if sum > 0 {
                    total += sum
                    sawValue = true
                    continue
                }
                if let mins = minutesBetweenSleepStrings(
                    obj.value(forKey: "sleepTime") as? String,
                    obj.value(forKey: "wakeTime") as? String
                ), mins > 0 {
                    total += mins
                    sawValue = true
                    continue
                }
            }

            let dict: NSDictionary?
            if let d = item as? NSDictionary {
                dict = d
            } else if let d = item as? [AnyHashable: Any] {
                dict = d as NSDictionary
            } else {
                dict = nil
            }

            guard let dict else { continue }

            if let sleHour = doubleFromAny(dict["SLE_HOUR"]),
               let sleMin = doubleFromAny(dict["SLE_MINUTE"]) {
                let minutes = Int((sleHour * 60.0 + sleMin).rounded())
                if minutes > 0 {
                    total += minutes
                    sawValue = true
                    continue
                }
            }

            if let deep = doubleFromAny(dict["DEEP_HOUR"]),
               let light = doubleFromAny(dict["LIGHT_HOUR"]) {
                let minutes = Int(((deep + light) * 60.0).rounded())
                if minutes > 0 {
                    total += minutes
                    sawValue = true
                    continue
                }
            }

            if let mins = minutesBetweenSleepStrings(
                dict["SLEEP_TIME"] as? String ?? dict["sleepTime"] as? String,
                dict["WAKE_TIME"] as? String ?? dict["wakeTime"] as? String
            ), mins > 0 {
                total += mins
                sawValue = true
                continue
            }

            if doubleFromAny(dict["SLE_HOUR"]) == nil,
               let m = intFromAny(dict["SLE_MINUTE"] ?? dict["sleepDuration"] ?? dict["SleepDuration"]),
               m > 0 {
                // Only raw minutes when hour field is absent (avoid double-count).
                total += m
                sawValue = true
            }
        }

        guard sawValue else { return nil }
        // Clamp to a plausible single-day total (0…24h).
        return min(total, 24 * 60)
    }

    private static func intFromAny(_ value: Any?) -> Int? {
        guard let value else { return nil }
        if let n = value as? NSNumber { return n.intValue }
        if let n = value as? Int { return n }
        if let n = value as? Double { return Int(n.rounded()) }
        if let s = value as? String {
            let trimmed = s.trimmingCharacters(in: .whitespacesAndNewlines)
            if let v = Int(trimmed) { return v }
            if let v = Double(trimmed.replacingOccurrences(of: ",", with: ".")) {
                return Int(v.rounded())
            }
        }
        return nil
    }

    private static func doubleFromAny(_ value: Any?) -> Double? {
        guard let value else { return nil }
        if let n = value as? NSNumber { return n.doubleValue }
        if let n = value as? Double { return n }
        if let n = value as? Int { return Double(n) }
        if let s = value as? String {
            return Double(s.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: "."))
        }
        return nil
    }

    /// Veepoo ordinary sleep timestamps look like `2017/02/09 01:15`.
    private static func minutesBetweenSleepStrings(_ start: String?, _ end: String?) -> Int? {
        guard let start, let end else { return nil }
        let formats = ["yyyy/MM/dd HH:mm", "yyyy-MM-dd HH:mm", "yyyy/MM/dd HH:mm:ss"]
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        for format in formats {
            formatter.dateFormat = format
            if let s = formatter.date(from: start), let e = formatter.date(from: end), e > s {
                let mins = Int(e.timeIntervalSince(s) / 60.0)
                if mins > 0, mins <= 24 * 60 { return mins }
            }
        }
        return nil
    }

    private func appendChart(_ value: Double, to series: inout [ChartPoint]) {
        guard value.isFinite else { return }
        chartSeq += 1
        series.append(ChartPoint(id: chartSeq, value: value))
        if series.count > chartCap {
            series.removeFirst(series.count - chartCap)
        }
    }

    /// Obj-C `NSArray *filterSignals` may be nil; Swift bridge can still crash on `.count`.
    private static func safeECGFilterSignalCount(_ model: VPECGTestDataModel?) -> Int {
        guard let model else { return 0 }
        if let arr = model.value(forKey: "filterSignals") as? NSArray {
            return arr.count
        }
        return 0
    }

    private static func clampECGProgress(_ progress: UInt) -> Int {
        Int(min(progress, 100))
    }

    /// Converts `filterSignals` ADC samples to mV using Veepoo’s helper (falls back to scaled ADC if conversion returns flat zero).
    private static func ecgWaveformMillivolts(from model: VPECGTestDataModel?) -> [Float] {
        guard let model else { return [] }
        guard let raw = model.value(forKey: "filterSignals") as? NSArray, raw.count > 0 else { return [] }

        let ecgType = (model.ecgType as String?) ?? "1"
        let testType = (model.type as String?) ?? "1"
        let gain = model.getGainValue()

        // Keep only the tail so UI + conversion stay responsive (SDK appends continuously).
        let maxRaw = 12_000
        let startIdx = max(0, raw.count - maxRaw)

        var out: [Float] = []
        out.reserveCapacity(raw.count - startIdx)
        for i in startIdx..<raw.count {
            let el = raw.object(at: i)
            let adc: CGFloat
            if let n = el as? NSNumber {
                adc = CGFloat(truncating: n)
            } else {
                continue
            }
            var mv = CGFloat(
                VPECGTestDataModel.convertToMv(
                    withValue: adc,
                    ecgType: ecgType,
                    testType: testType,
                    gain: gain
                )
            )
            if mv == 0, adc != 0 {
                mv = adc / 128.0
            }
            out.append(Float(mv))
        }
        return out
    }

    private static func ecgLiveHeartRate(from model: VPECGTestDataModel?) -> Int? {
        guard let model else { return nil }
        guard let mu = model.value(forKey: "muHearts") as? NSArray, mu.count > 0 else { return nil }
        guard let last = mu.lastObject as? NSNumber else { return nil }
        let v = last.intValue
        return v > 0 ? v : nil
    }

    private static func downsampleECG(_ values: [Float], maxPoints: Int) -> [Float] {
        guard values.count > maxPoints else { return values }
        let step = max(1, values.count / maxPoints)
        var result: [Float] = []
        result.reserveCapacity(min(maxPoints, values.count / step + 1))
        var i = 0
        while i < values.count {
            result.append(values[i])
            i += step
        }
        return result
    }
}
