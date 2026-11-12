import Foundation

/// Temporary product gates for first-release scope.
enum AppFeatureFlags {
    /// Live on-watch measure (pulse / SpO₂ / BP / …). Keep off until BLE measure is stable.
    static let liveWatchMeasureEnabled = false
}
