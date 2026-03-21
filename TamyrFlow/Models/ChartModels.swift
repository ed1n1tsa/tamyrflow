import Foundation

/// One sample for Swift Charts (monotonic index survives trimming).
struct ChartPoint: Identifiable, Equatable {
    let id: Int
    let value: Double
}
