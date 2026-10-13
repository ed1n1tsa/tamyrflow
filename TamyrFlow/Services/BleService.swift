import Foundation
import Combine
import CoreBluetooth
import UIKit
import VeepooBleSDK

/// BLE + Veepoo central manager. SDK touch is deferred until `configureSDKIfNeeded()` so UIKit/CBCentralManager are ready (avoids launch crashes).
@MainActor
final class BleService: ObservableObject {
    @Published private(set) var scannedDevices: [ScanDevice] = []
    @Published private(set) var connectionStatus: DeviceConnectionStatus = .disconnected
    @Published private(set) var isBluetoothOn = false
    @Published private(set) var connectedDevice: VPPeripheralModel?
    @Published private(set) var batteryInfo: BatteryInfo?
    @Published private(set) var errorText: String?
    /// `true` only after `configureSDKIfNeeded()` successfully obtained the central manager. Avoids calling Veepoo APIs out of order (common crash).
    @Published private(set) var isSDKConfigured = false
    /// Human-readable BLE state for debugging (includes CoreBluetooth authorization on iOS 13.1+).
    @Published private(set) var bluetoothDiagnostic: String = ""
    /// `true` while BLE scan is active (after successful `startScan` until `stopScan`).
    @Published private(set) var isScanning = false
    /// `true` while Veepoo SDK has not yet created `CBCentralManager` (lazy). UI must not treat this as “Bluetooth off”.
    @Published private(set) var isPhoneBluetoothStatePending = true

    private var bleManager: VPBleCentralManage?
    private var scanMap: [String: ScanDevice] = [:]
    private var didConfigureSDK = false
    private var bluetoothWakeProbeTask: Task<Void, Never>?

    init() {
        // Intentionally empty — call configureSDKIfNeeded() after first frame (e.g. from ContentView.task).
    }

    /// Call once after the app window is up (main thread).
    func configureSDKIfNeeded() {
        guard !didConfigureSDK else { return }
        guard let manager = VPBleCentralManage.sharedBleManager() else {
            errorText = L10n.Err.veepooUnavailable
            return
        }
        didConfigureSDK = true
        bleManager = manager

        // Official persistence path (wiki): assign VPPeripheralManage before any data APIs.
        manager.peripheralManage = VPPeripheralManage.shareVPPeripheralManager()

        manager.isLogEnable = true
        manager.automaticConnection = false
        // If YES, Veepoo SDK only shows devices with their manufacturer ID — easy to see "no devices".
        manager.manufacturerIDFilter = false

        manager.vpBleCentralManageChangeBlock = { [weak self] _ in
            Task { @MainActor in
                guard let self, let m = self.bleManager else { return }
                self.applyCentralBluetoothState(from: m)
                if !self.isBluetoothOn {
                    self.connectionStatus = .disconnected
                }
            }
        }

        manager.vpBleConnectStateChangeBlock = { [weak self] state in
            Task { @MainActor in
                guard let self else { return }
                self.connectionStatus = Self.mapConnectionState(state)
                if state.rawValue == 3 {
                    self.connectedDevice = self.bleManager?.peripheralModel
                }
                if state.rawValue == 0 {
                    self.connectedDevice = nil
                    self.batteryInfo = nil
                }
                // Linking often wakes the lazy CBCentralManager — refresh phone BT row immediately.
                if let m = self.bleManager {
                    self.applyCentralBluetoothState(from: m)
                }
            }
        }

        isSDKConfigured = true

        // SDK callback often fires only on *changes*. If Bluetooth was already on at launch, read CBCentralManager.state now.
        applyCentralBluetoothState(from: manager)
        scheduleBluetoothStateRefresh()
        scheduleBluetoothWakeProbe()
    }

    /// Call when returning from Settings (e.g. after enabling Bluetooth permission).
    func refreshBluetoothStateIfConfigured() {
        guard let m = bleManager else { return }
        applyCentralBluetoothState(from: m)
        if m.centralManager == nil {
            scheduleBluetoothWakeProbe()
        }
    }

    /// Poll until SDK exposes `CBCentralManager` (otherwise UI looked “BT off” until any command e.g. Auto HR).
    private func scheduleBluetoothWakeProbe() {
        bluetoothWakeProbeTask?.cancel()
        bluetoothWakeProbeTask = Task { @MainActor in
            for _ in 0..<50 {
                guard !Task.isCancelled else { return }
                guard let m = bleManager else { return }
                applyCentralBluetoothState(from: m)
                if m.centralManager != nil { return }
                try? await Task.sleep(nanoseconds: 400_000_000)
            }
            guard let m = bleManager else { return }
            applyCentralBluetoothState(from: m)
        }
    }

    /// Re-read `CBCentralManager.state` after a short delay (state is often `.unknown` for a moment right after init).
    private func scheduleBluetoothStateRefresh() {
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 250_000_000)
            guard let m = bleManager else { return }
            applyCentralBluetoothState(from: m)
            try? await Task.sleep(nanoseconds: 750_000_000)
            guard let m2 = bleManager else { return }
            applyCentralBluetoothState(from: m2)
        }
    }

    /// Single source of truth from Core Bluetooth (matches `VPCentralManagerState` 0…5).
    private func applyCentralBluetoothState(from manager: VPBleCentralManage) {
        let authText: String
        if #available(iOS 13.1, *) {
            authText = " auth=\(CBManager.authorization.rawValue)"
        } else {
            authText = ""
        }

        guard let cm = manager.centralManager else {
            // SDK may create `CBCentralManager` lazily — don’t treat as “powered off” forever.
            isPhoneBluetoothStatePending = true
            isBluetoothOn = false
            bluetoothDiagnostic = "centralManager=nil\(authText) (SDK still initializing — try Start scan)"
            return
        }
        isPhoneBluetoothStatePending = false
        let state = cm.state
        isBluetoothOn = (state == .poweredOn)
        bluetoothDiagnostic = "CBCentralManager.state=\(state.rawValue)\(authText)"

        switch state {
        case .unauthorized:
            errorText = L10n.Err.btPermissionDetail
        case .poweredOff:
            errorText = L10n.Err.btOff
        case .unsupported:
            errorText = L10n.Err.btUnsupported
        case .poweredOn:
            clearBluetoothOnlyErrors()
        case .unknown, .resetting:
            clearBluetoothOnlyErrors()
        @unknown default:
            break
        }

        if #available(iOS 13.1, *) {
            switch CBManager.authorization {
            case .denied, .restricted:
                errorText = L10n.Err.btPermission
            case .notDetermined, .allowedAlways:
                break
            @unknown default:
                break
            }
        }
    }

    private func clearBluetoothOnlyErrors() {
        guard let e = errorText else { return }
        let bt: Set<String> = [
            L10n.Err.btPermission,
            L10n.Err.btPermissionDetail,
            L10n.Err.btOff,
            L10n.Err.btUnsupported,
            L10n.Err.btScan,
        ]
        if bt.contains(e) {
            errorText = nil
        }
    }

    /// Only these states make scanning pointless; `.unknown` often appears briefly and should still allow a scan attempt.
    private func shouldBlockScan(central: CBCentralManager?) -> Bool {
        if #available(iOS 13.1, *) {
            switch CBManager.authorization {
            case .denied, .restricted:
                return true
            case .notDetermined, .allowedAlways:
                break
            @unknown default:
                break
            }
        }
        guard let cm = central else { return false }
        switch cm.state {
        case .poweredOff, .unsupported, .unauthorized:
            return true
        case .unknown, .resetting, .poweredOn:
            return false
        @unknown default:
            return false
        }
    }

    func openAppSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func startScan() {
        configureSDKIfNeeded()
        if let m = bleManager {
            applyCentralBluetoothState(from: m)
        }
        if shouldBlockScan(central: bleManager?.centralManager) {
            isScanning = false
            if errorText == nil {
                errorText = L10n.Err.btScan
            }
            return
        }
        errorText = nil
        scannedDevices = []
        scanMap.removeAll()
        isScanning = true
        bleManager?.veepooSDKStartScanDeviceAndReceiveScanningDevice { [weak self] model in
            guard let self else { return }
            Task { @MainActor in
                guard let model else { return }
                let address = model.deviceAddress ?? ""
                let key = address.isEmpty ? (model.deviceName ?? UUID().uuidString) : address
                let item = ScanDevice(
                    id: key,
                    name: model.deviceName ?? "Unknown Device",
                    address: address,
                    rssi: model.rssi?.intValue ?? 0,
                    rawModel: model
                )
                self.scanMap[key] = item
                self.scannedDevices = self.scanMap.values.sorted(by: { $0.rssi > $1.rssi })
            }
        }
    }

    func stopScan() {
        isScanning = false
        bleManager?.veepooSDKStopScanDevice()
    }

    func connect(_ device: ScanDevice) {
        configureSDKIfNeeded()
        stopScan()
        connectionStatus = .connecting
        bleManager?.veepooSDKConnectDevice(device.rawModel) { [weak self] state in
            Task { @MainActor in
                self?.connectionStatus = Self.mapDeviceConnectState(state)
            }
        }
    }

    func disconnect() {
        bleManager?.veepooSDKDisconnectDevice()
    }

    func readBattery() {
        configureSDKIfNeeded()
        guard bleManager?.isConnected == true else {
            errorText = L10n.Err.readBattery
            return
        }
        bleManager?.peripheralManage.veepooSDKReadDeviceBatteryAndChargeInfo { [weak self] isPercent, chargeState, lowBat, battery in
            Task { @MainActor in
                self?.batteryInfo = BatteryInfo(
                    isPercent: isPercent,
                    isLowBattery: lowBat,
                    battery: Int(battery),
                    chargeState: chargeState
                )
            }
        }
    }

    func readBatteryAsync() async {
        configureSDKIfNeeded()
        guard bleManager?.isConnected == true else { return }
        await withCheckedContinuation { (cont: CheckedContinuation<Void, Never>) in
            var resumed = false
            let finish: () -> Void = {
                guard !resumed else { return }
                resumed = true
                cont.resume()
            }
            bleManager?.peripheralManage.veepooSDKReadDeviceBatteryAndChargeInfo { [weak self] isPercent, chargeState, lowBat, battery in
                Task { @MainActor in
                    self?.batteryInfo = BatteryInfo(
                        isPercent: isPercent,
                        isLowBattery: lowBat,
                        battery: Int(battery),
                        chargeState: chargeState
                    )
                    finish()
                }
            }
            // SDK sometimes never calls back — do not leak the continuation (freezes awaiters).
            Task {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                finish()
            }
        }
    }

    private static func mapConnectionState(_ state: VPDeviceConnectState) -> DeviceConnectionStatus {
        switch state.rawValue {
        case 0: return .disconnected
        case 1: return .connecting
        case 2: return .connected
        case 3: return .verified
        case 4: return .failed
        case 6: return .timeout
        default: return .disconnected
        }
    }

    private static func mapDeviceConnectState(_ state: DeviceConnectState) -> DeviceConnectionStatus {
        switch state.rawValue {
        case 1: return .connecting
        case 2: return .connected
        case 4: return .verified
        case 3, 5: return .failed
        case 6: return .timeout
        default: return .disconnected
        }
    }
}
