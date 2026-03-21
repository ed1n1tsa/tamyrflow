import Foundation

/// `TabView` selection tags (keep order in sync with `RootTabView`).
enum MainTab: Int, Hashable, CaseIterable {
    case scan = 0
    case home = 1
    case heart = 2
    case spo2 = 3
    case temp = 4
    case vitals = 5
    case ecg = 6
    case micro = 7
    case settings = 8
}
