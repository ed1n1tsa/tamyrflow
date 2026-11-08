import Foundation

enum VitalMetricFormatters {
    static func displayValue(_ item: VitalMeasurement?, kind: IndicatorKind) -> String {
        guard let item else { return L10n.Pulse.noData }
        return displayValue(item.value, secondary: item.valueSecondary, kind: kind)
    }

    static func displayValue(_ value: Double?, secondary: Double? = nil, kind: IndicatorKind) -> String {
        guard let value else { return L10n.Pulse.noData }
        switch kind {
        case .spo2:
            return "\(Int(value.rounded()))%"
        case .temperature:
            return String(format: "%.1f ℃", value)
        case .bloodPressure:
            if let secondary {
                return "\(Int(value.rounded()))/\(Int(secondary.rounded()))"
            }
            return "\(Int(value.rounded()))"
        case .steps:
            let n = Int(value.rounded())
            return n.formatted(.number.grouping(.automatic))
        case .sleep:
            let minutes = Int(value.rounded())
            return String(format: L10n.Indicators.sleepValueFormat, minutes / 60, minutes % 60)
        default:
            return "\(Int(value.rounded()))"
        }
    }

    static func displayWithUnit(_ value: Double?, secondary: Double? = nil, kind: IndicatorKind) -> String {
        guard let value else { return L10n.Pulse.noData }
        switch kind {
        case .spo2:
            return "\(Int(value.rounded())) \(L10n.Indicators.unit(for: .spo2))"
        case .temperature:
            return String(format: "%.1f %@", value, L10n.Indicators.unit(for: .temperature))
        case .bloodPressure:
            if let secondary {
                return "\(Int(value.rounded()))/\(Int(secondary.rounded())) \(L10n.Indicators.unit(for: .bloodPressure))"
            }
            return "\(Int(value.rounded())) \(L10n.Indicators.unit(for: .bloodPressure))"
        case .steps:
            return "\(displayValue(value, kind: .steps)) \(L10n.Indicators.unit(for: .steps))"
        case .sleep:
            return displayValue(value, kind: .sleep)
        default:
            return displayValue(value, secondary: secondary, kind: kind)
        }
    }
}
