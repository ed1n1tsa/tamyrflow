import Combine
import Foundation

/// Primary app tabs (Figma: Home / Metrics / Activity / Goals / Profile).
enum MainTab: Int, Hashable, CaseIterable {
    case home = 0
    case metrics = 1
    case activity = 2
    case goals = 3
    case profile = 4

    var titleKey: String {
        switch self {
        case .home: return "tab_home"
        case .metrics: return "tab_metrics"
        case .activity: return "tab_activity"
        case .goals: return "tab_goals"
        case .profile: return "tab_profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .metrics: return "chart.bar.fill"
        case .activity: return "figure.run"
        case .goals: return "trophy.fill"
        case .profile: return "person.fill"
        }
    }
}
