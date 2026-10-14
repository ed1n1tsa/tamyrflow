import Foundation
import SwiftUI

enum IndicatorsPeriod: Int, CaseIterable, Identifiable, Hashable {
    case days7 = 7
    case days30 = 30
    case days90 = 90

    var id: Int { rawValue }

    var dayCount: Int { rawValue }
}

enum IndicatorKind: String, CaseIterable, Identifiable, Hashable {
    case heartRate
    case spo2
    case temperature
    case bloodPressure
    case steps
    case sleep

    var id: String { rawValue }

    /// Supabase `metric_type` raw value.
    var metricKey: String {
        switch self {
        case .heartRate: return "heart_rate"
        case .spo2: return "spo2"
        case .temperature: return "temperature"
        case .bloodPressure: return "blood_pressure"
        case .steps: return "steps"
        case .sleep: return "sleep"
        }
    }

    var usesBarChart: Bool { self == .sleep }

    var iconSystemName: String {
        switch self {
        case .heartRate: return "heart.fill"
        case .spo2: return "drop.fill"
        case .temperature: return "thermometer.medium"
        case .bloodPressure: return "waveform.path.ecg"
        case .steps: return "figure.walk"
        case .sleep: return "moon.fill"
        }
    }

    var accent: Color {
        switch self {
        case .heartRate: return Color(red: 1.0, green: 0.32, blue: 0.42)
        case .spo2: return Color(red: 0.35, green: 0.62, blue: 1.0)
        case .temperature: return Color(red: 1.0, green: 0.58, blue: 0.22)
        case .bloodPressure: return Color(red: 0.68, green: 0.42, blue: 1.0)
        case .steps: return Color(red: 0.18, green: 0.85, blue: 0.72)
        case .sleep: return Color(red: 0.28, green: 0.48, blue: 1.0)
        }
    }
}

struct IndicatorDayPoint: Identifiable, Equatable {
    var id: String { dayKey }
    /// yyyy-MM-dd
    let dayKey: String
    let date: Date
    let value: Double
    let valueSecondary: Double?
}

struct IndicatorCardModel: Identifiable, Equatable {
    var id: IndicatorKind { kind }
    let kind: IndicatorKind
    /// Latest / representative value for the period.
    let primaryValue: Double?
    let secondaryValue: Double?
    /// Percent change of recent half vs earlier half. Nil if not enough data.
    let trendPercent: Double?
    let series: [IndicatorDayPoint]
}
