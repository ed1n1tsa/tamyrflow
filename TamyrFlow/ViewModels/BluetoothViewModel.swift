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
    private var healthBootstrapTask: Task<Void, Never>?
    /// Invisible Auto-HR off→on every 7s while app is foreground (keeps SpO₂/health pipe on some bands).
    private var autoHRPulseTask: Task<Void, Never>?
    private var postConnectMetricsTask: Task<Void, Never>?
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
                    self.healthBootstrapTask?.cancel()
                    self.postConnectMetricsTask?.cancel()
                    self.stopAutoHRPulseLoop()
                case .verified:
                    self.autoHR = true
                    self.healthService.bootstrapHealthChannelAfterVerification()
                    self.scheduleStaggeredHealthBootstrap()
                    // Do NOT start daily dump here — connect success UI must stay responsive.
                    // Metrics sync runs after the pairing flow dismisses / My Watch appears.
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

    /// JL + Veepoo bands often accept health/SpO₂ only after Auto HR is sent; repeat while link stays verified.
    private func scheduleStaggeredHealthBootstrap() {
        healthBootstrapTask?.cancel()
        healthBootstrapTask = Task { [weak self] in
            guard let self else { return }
            let delays: [Double] = [0.5, 1.2, 2.5, 5.0, 9.0, 14.0]
            for d in delays {
                try? await Task.sleep(nanoseconds: UInt64(d * 1_000_000_000))
                guard !Task.isCancelled else { return }
                guard self.bleService.connectionStatus == .verified else { return }
                self.autoHR = true
                self.healthService.bootstrapHealthChannelAfterVerification()
                self.bleService.refreshBluetoothStateIfConfigured()
            }
        }
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

    /// Pull-to-refresh: wake BLE stack, re-open health pipe, time sync, battery, then daily data if idle.
    func performPullToRefresh(auth: AuthService? = nil) async {
        if let auth { authService = auth }
        bleService.configureSDKIfNeeded()
        bleService.refreshBluetoothStateIfConfigured()
        try? await Task.sleep(nanoseconds: 250_000_000)

        guard bleService.connectionStatus == .verified, healthService.isConnected else { return }

        autoHR = true
        healthService.bootstrapHealthChannelAfterVerification()
        healthService.ensureLiveMeasurementChannel()
        healthService.syncTime()
        await bleService.readBatteryAsync()

        applyStatureToHealthService()
        // Daily dump fills SDK DB; then we read steps/sleep from VPDataBaseOperation (not AddManage APIs).
        await syncStepsAndSleepToCloud(auth: auth ?? authService, pullDailyFirst: true, showHUD: true)
        if healthService.measurementHUD != nil {
            healthService.dismissMeasurementOverlay()
        }
    }

    /// Read steps + sleep from the band and upsert into Supabase (Activity / Goals).
    func syncStepsAndSleepToCloud(
        auth: AuthService? = nil,
        pullDailyFirst: Bool = true,
        showHUD: Bool = false
    ) async {
        let resolvedAuth = auth ?? authService
        guard bleService.connectionStatus == .verified, healthService.isConnected else { return }
        applyStatureToHealthService()

        let snapshot = await healthService.syncStepsAndSleepFromBand(
            showHUD: showHUD,
            pullDailyFirst: pullDailyFirst
        )

        guard let resolvedAuth, resolvedAuth.session != nil else { return }
        await WatchMetricsBridge.persistStepsAndSleep(
            auth: resolvedAuth,
            steps: snapshot.steps,
            sleepMinutes: snapshot.sleepMinutes
        )
    }

    private func applyStatureToHealthService() {
        healthService.userStatureCm = UInt(Int(height) ?? 175)
    }

    /// Call after the connect flow is dismissed so the success screen never blocks on SDK I/O.
    func scheduleDeferredStepsSleepSync(delayNanoseconds: UInt64 = 1_200_000_000) {
        postConnectMetricsTask?.cancel()
        postConnectMetricsTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled, let self else { return }
            guard self.bleService.connectionStatus == .verified else { return }
            await self.syncStepsAndSleepToCloud(pullDailyFirst: true, showHUD: false)
        }
    }

    /// Call from views with `scenePhase == .active` (and onAppear) so Auto-HR pulse runs only in foreground.
    func handleAppForegroundActive(_ active: Bool) {
        setAppForegroundActive(active)
        if active {
            bleService.refreshBluetoothStateIfConfigured()
            if bleService.connectionStatus == .verified {
                healthService.ensureLiveMeasurementChannel()
                bleService.refreshBluetoothStateIfConfigured()
            }
        }
    }

    /// Starts/stops the 7s Auto-HR pulse loop (no change to the Settings toggle binding).
    private func setAppForegroundActive(_ active: Bool) {
        stopAutoHRPulseLoop()
        guard active else { return }
        if bleService.connectionStatus == .verified, healthService.isConnected {
            healthService.pulseAutoHRHealthChannel(restoreTo: autoHR)
        }
        startAutoHRPulseLoop()
    }

    private func startAutoHRPulseLoop() {
        autoHRPulseTask?.cancel()
        autoHRPulseTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 7_000_000_000)
                guard !Task.isCancelled else { break }
                guard let self else { break }
                guard self.bleService.connectionStatus == .verified,
                      self.healthService.isConnected else { continue }
                self.healthService.pulseAutoHRHealthChannel(restoreTo: self.autoHR)
            }
        }
    }

    private func stopAutoHRPulseLoop() {
        autoHRPulseTask?.cancel()
        autoHRPulseTask = nil
    }

    /// Cold start / return: if watch already verified, align like official “auto” flow.
    func performLaunchWatchSyncIfPossible(auth: AuthService? = nil) async {
        if let auth { authService = auth }
        bleService.configureSDKIfNeeded()
        bleService.refreshBluetoothStateIfConfigured()
        try? await Task.sleep(nanoseconds: 500_000_000)

        guard bleService.isBluetoothOn else { return }
        guard bleService.connectionStatus == .verified, healthService.isConnected else { return }

        autoHR = true
        healthService.bootstrapHealthChannelAfterVerification()
        healthService.ensureLiveMeasurementChannel()
        healthService.syncTime()
        await bleService.readBatteryAsync()
        // Dump band → SDK DB → steps/sleep (needed on VPPeripheralManage).
        await syncStepsAndSleepToCloud(auth: auth ?? authService, pullDailyFirst: true, showHUD: false)
    }
}
