import Foundation
import Combine
import VeepooBleSDK

@MainActor
final class BluetoothViewModel: ObservableObject {
    @Published var height: String = "175"
    @Published var weight: String = "70"
    @Published var age: String = "30"
    @Published var sex: Int = 1
    @Published var targetSteps: String = "8000"
    @Published var useMetric: Bool = true
    @Published var use24h: Bool = true
    @Published var autoHR: Bool = false
    @Published var autoTemperature: Bool = false

    let bleService: BleService
    let healthService: VeepooHealthService

    private var cancellables = Set<AnyCancellable>()
    private var postConnectMetricsTask: Task<Void, Never>?
    private var realtimeStepPollTask: Task<Void, Never>?
    /// Set from the authenticated shell so post-connect / pull sync can write Supabase.
    private weak var authService: AuthService?

    init(bleService: BleService? = nil) {
        let resolvedBleService = bleService ?? BleService()
        self.bleService = resolvedBleService
        self.healthService = VeepooHealthService(bleService: resolvedBleService)

        resolvedBleService.$connectionStatus
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .disconnected, .failed, .timeout:
                    self.postConnectMetricsTask?.cancel()
                    self.stopRealtimeStepPolling()
                case .verified:
                    // Connect: time + battery + realtime steps only. Never AllData / band sleep (SDK crash).
                    self.healthService.syncTime()
                    Task { await self.bleService.readBatteryAsync() }
                    self.startRealtimeStepPolling()
                default:
                    break
                }
            }
            .store(in: &cancellables)

        // RootTabView reads `vm.healthService.*` — without forwarding, overlay/buttons won’t refresh when only health/ BLE publish.
        healthService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)

        resolvedBleService.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.objectWillChange.send() }
            .store(in: &cancellables)
    }

    var statusText: String {
        bleService.connectionStatus.localizedLabel
    }

    var batteryText: String {
        guard let info = bleService.batteryInfo else { return "-" }
        let unit = info.isPercent ? "%" : "/4"
        return "\(info.battery)\(unit)"
    }

    var chargeStateText: String {
        guard let info = bleService.batteryInfo else { return "-" }
        switch info.chargeState.rawValue {
        case 1: return L10n.Battery.charging
        case 3: return L10n.Battery.full
        default: return L10n.Battery.normal
        }
    }

    var currentDeviceName: String {
        bleService.connectedDevice?.deviceName ?? "-"
    }

    var currentDeviceAddress: String {
        bleService.connectedDevice?.deviceAddress ?? "-"
    }

    func syncPersonalInfo() {
        let h = Int(height) ?? 175
        let w = Int(weight) ?? 70
        let a = Int(age) ?? 30
        let t = Int(targetSteps) ?? 8000
        healthService.syncPersonalInfo(height: h, weight: w, age: a, sex: sex, targetStep: t)
        healthService.userStatureCm = UInt(h)
    }

    /// Sends Settings toggles to the band (only after BLE SDK is configured and device connected).
    func applyDeviceTogglesToWatch() {
        healthService.setMetric(useMetric)
        healthService.setTimeFormat24h(use24h)
        healthService.setAutoHR(autoHR)
        healthService.setAutoTemperature(autoTemperature)
    }

    func attachAuth(_ auth: AuthService) {
        authService = auth
    }

    /// Pull-to-refresh: battery + wiki realtime steps/kcal (+ safe sleep). No AutoHR pulse.
    func performPullToRefresh(auth: AuthService? = nil) async {
        if let auth { authService = auth }
        bleService.configureSDKIfNeeded()
        bleService.refreshBluetoothStateIfConfigured()
        try? await Task.sleep(nanoseconds: 250_000_000)

        guard bleService.connectionStatus == .verified, healthService.isConnected else { return }

        healthService.syncTime()
        await bleService.readBatteryAsync()
        await syncActivityMetricsToCloud(auth: auth ?? authService)
        if healthService.measurementHUD != nil {
            healthService.dismissMeasurementOverlay()
        }
    }

    /// Realtime Step/Dis/Cal → Supabase. No band sleep / AllData (connect crash fix).
    func syncActivityMetricsToCloud(auth: AuthService? = nil) async {
        let resolvedAuth = auth ?? authService
        guard bleService.connectionStatus == .verified, healthService.isConnected else { return }
        applyStatureToHealthService()

        let totals = await healthService.syncActivityMetricsFromBand(includeSleep: false)
        guard let resolvedAuth, resolvedAuth.session != nil else { return }
        await WatchMetricsBridge.persistBandDayTotals(
            auth: resolvedAuth,
            steps: totals.steps,
            caloriesKcal: totals.caloriesKcal,
            sleepMinutes: nil
        )
    }

    /// Legacy name used by older call sites.
    func syncStepsAndSleepToCloud(
        auth: AuthService? = nil,
        pullDailyFirst: Bool = false,
        showHUD: Bool = false
    ) async {
        _ = pullDailyFirst
        _ = showHUD
        await syncActivityMetricsToCloud(auth: auth)
    }

    private func applyStatureToHealthService() {
        if let deviceStature = bleService.connectedDevice?.deviceStature, deviceStature > 0 {
            healthService.userStatureCm = deviceStature
        } else {
            healthService.userStatureCm = UInt(Int(height) ?? 175)
        }
    }

    /// After pairing UI dismisses — battery already requested on verify; persist realtime steps only.
    func scheduleDeferredStepsSleepSync(delayNanoseconds: UInt64 = 1_200_000_000) {
        postConnectMetricsTask?.cancel()
        postConnectMetricsTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled, let self else { return }
            guard self.bleService.connectionStatus == .verified else { return }
            await self.bleService.readBatteryAsync()
            await self.syncActivityMetricsToCloud()
        }
    }

    /// Wiki-style realtime step poll (~8s) while verified — keeps Activity close to the watch face.
    private func startRealtimeStepPolling() {
        stopRealtimeStepPolling()
        realtimeStepPollTask = Task { [weak self] in
            // First sample shortly after verify.
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            while !Task.isCancelled {
                guard let self else { break }
                guard self.bleService.connectionStatus == .verified,
                      self.healthService.isConnected else { break }
                let totals = await self.healthService.fetchRealtimeStepTotals()
                if let auth = self.authService, auth.session != nil {
                    await WatchMetricsBridge.persistBandDayTotals(
                        auth: auth,
                        steps: totals.steps,
                        caloriesKcal: totals.caloriesKcal,
                        sleepMinutes: nil
                    )
                }
                try? await Task.sleep(nanoseconds: 8_000_000_000)
            }
        }
    }

    private func stopRealtimeStepPolling() {
        realtimeStepPollTask?.cancel()
        realtimeStepPollTask = nil
    }

    /// Foreground: refresh BT state only — no global AutoHR pulse.
    func handleAppForegroundActive(_ active: Bool) {
        guard active else { return }
        bleService.refreshBluetoothStateIfConfigured()
        if bleService.connectionStatus == .verified {
            startRealtimeStepPolling()
        }
    }

    /// Cold start: if already verified, sync time/battery + activity metrics (no AutoHR spam).
    func performLaunchWatchSyncIfPossible(auth: AuthService? = nil) async {
        if let auth { authService = auth }
        bleService.configureSDKIfNeeded()
        bleService.refreshBluetoothStateIfConfigured()
        try? await Task.sleep(nanoseconds: 500_000_000)

        guard bleService.isBluetoothOn else { return }
        guard bleService.connectionStatus == .verified, healthService.isConnected else { return }

        healthService.syncTime()
        await bleService.readBatteryAsync()
        startRealtimeStepPolling()
        await syncActivityMetricsToCloud(auth: auth ?? authService)
    }
}
