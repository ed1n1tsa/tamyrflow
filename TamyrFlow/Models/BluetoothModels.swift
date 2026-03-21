import Foundation
import VeepooBleSDK

enum DeviceConnectionStatus: String {
    case disconnected = "Disconnected"
    case connecting = "Connecting"
    case connected = "Connected"
    case verified = "Verified"
    case failed = "Failed"
    case timeout = "Timeout"
}

enum BleOperation: String {
    case idle
    case readingDailyData
    case heartTest
    case oxygenTest
    case temperatureTest
    case ecgTest
    case microTest
    case bloodPressureTest
    case bloodGlucoseTest
    case readingSteps
    case readingSleep
}

struct ScanDevice: Identifiable, Equatable {
    let id: String
    let name: String
    let address: String
    let rssi: Int
    let rawModel: VPPeripheralModel
}

struct BatteryInfo {
    let isPercent: Bool
    let isLowBattery: Bool
    let battery: Int
    let chargeState: VPDeviceChargeState
}

struct HeartRateReading {
    let state: VPTestHeartState
    let value: Int
}

struct OxygenReading {
    let state: VPTestOxygenState
    let value: Int
}

struct TemperatureReading {
    let state: VPTemperatureTestState
    let enable: Bool
    let progress: Int
    let bodyTemperature: Double
    let skinTemperature: Double
}

struct ECGReading {
    let state: VPTestECGState
    let progress: Int
    let sampleCount: Int
}

struct MicroTestReading {
    let progress: Int
    let model: VPMicroTestModel?
}

struct BloodPressureReading {
    let state: VPTestBloodState
    let progress: Int
    let systolic: Int
    let diastolic: Int
}

struct BloodGlucoseReading {
    let state: VPDeviceBloodGlucoseTestState
    let progress: Int
    /// Device reports mmol/L × 100.
    let valueRaw: UInt

    var mmol: Double { Double(valueRaw) / 100.0 }
}

extension DeviceConnectionStatus {
    var localizedLabel: String {
        switch self {
        case .disconnected: return L10n.Conn.disconnected
        case .connecting: return L10n.Conn.connecting
        case .connected: return L10n.Conn.connected
        case .verified: return L10n.Conn.verified
        case .failed: return L10n.Conn.failed
        case .timeout: return L10n.Conn.timeout
        }
    }
}

extension BleOperation {
    var localizedLabel: String {
        switch self {
        case .idle: return L10n.Op.idle
        case .readingDailyData: return L10n.Op.readingDaily
        case .heartTest: return L10n.Op.heart
        case .oxygenTest: return L10n.Op.oxygen
        case .temperatureTest: return L10n.Op.temperature
        case .ecgTest: return L10n.Op.ecg
        case .microTest: return L10n.Op.micro
        case .bloodPressureTest: return L10n.Op.bloodPressure
        case .bloodGlucoseTest: return L10n.Op.bloodGlucose
        case .readingSteps: return L10n.Op.readingSteps
        case .readingSleep: return L10n.Op.readingSleep
        }
    }
}
