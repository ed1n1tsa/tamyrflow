import Foundation

enum PulsePeriod: String, CaseIterable, Identifiable, Hashable {
    case day
    case week
    case month

    var id: String { rawValue }

    var dayCount: Int {
        switch self {
        case .day: return 1
        case .week: return 7
        case .month: return 30
        }
    }
}

enum PulseSource: String, Codable, Hashable {
    case device
    case appleHealth = "import"
    case manual

    var displayKey: String {
        switch self {
        case .device: return "tamyr_watch"
        case .appleHealth: return "apple_health"
        case .manual: return "manual"
        }
    }
}

enum PulseSyncState: Equatable {
    case idle
    case loading
    case success
    case noNewData
    case error(String)
    case noSource
}

struct PulseMeasurement: Identifiable, Equatable, Hashable {
    let id: UUID
    let value: Double
    let recordedAt: Date
    let source: PulseSource
    let deviceLabel: String?
    let recordType: String?
}

struct PulseChartPoint: Identifiable, Equatable {
    let id: String
    let date: Date
    let value: Double
    /// When false, chart should break the line (gap).
    let isConnected: Bool
}

struct PulsePeriodStats: Equatable {
    var average: Double?
    var minimum: Double?
    var minimumAt: Date?
    var maximum: Double?
    var maximumAt: Date?
    /// Percent change vs previous equal-length period. Nil if not enough data.
    var trendPercent: Double?
}
