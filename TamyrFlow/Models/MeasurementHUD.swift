import Foundation

/// Full-screen “measuring” overlay (official-app style feedback).
enum MeasurementKind: String, CaseIterable {
    case heart
    case oxygen
    case temperature
    case ecg
    case micro
    case bloodPressure
    case bloodGlucose
    case dailySync
    case stepsSnapshot
    case sleepSnapshot

    var titleKey: String {
        switch self {
        case .heart: return "measure_heart"
        case .oxygen: return "measure_spo2"
        case .temperature: return "measure_temp"
        case .ecg: return "measure_ecg"
        case .micro: return "measure_micro"
        case .bloodPressure: return "measure_bp"
        case .bloodGlucose: return "measure_glucose"
        case .dailySync: return "measure_daily_sync"
        case .stepsSnapshot: return "measure_steps"
        case .sleepSnapshot: return "measure_sleep"
        }
    }

    var systemImage: String {
        switch self {
        case .heart: return "heart.fill"
        case .oxygen: return "lungs.fill"
        case .temperature: return "thermometer.medium"
        case .ecg: return "waveform.path.ecg"
        case .micro: return "cross.case.fill"
        case .bloodPressure: return "heart.text.square.fill"
        case .bloodGlucose: return "drop.fill"
        case .dailySync: return "arrow.triangle.2.circlepath"
        case .stepsSnapshot: return "figure.walk"
        case .sleepSnapshot: return "moon.zzz.fill"
        }
    }
}

struct MeasurementHUDState: Equatable {
    var kind: MeasurementKind
    /// `nil` = indeterminate (spinner + shimmer bar).
    var progress01: Double?
}
