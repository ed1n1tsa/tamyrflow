import Foundation

enum AppNotificationKind: String, Codable, CaseIterable {
    case watch
    case goal
    case measure
    case sync
    case system

    var systemImage: String {
        switch self {
        case .watch: return "applewatch"
        case .goal: return "flag.fill"
        case .measure: return "heart.text.square.fill"
        case .sync: return "arrow.triangle.2.circlepath"
        case .system: return "bell.fill"
        }
    }
}

struct AppNotificationItem: Identifiable, Equatable, Codable {
    let id: UUID
    let kind: AppNotificationKind
    let title: String
    let body: String
    let createdAt: Date
    var isRead: Bool

    init(
        id: UUID = UUID(),
        kind: AppNotificationKind,
        title: String,
        body: String,
        createdAt: Date = Date(),
        isRead: Bool = false
    ) {
        self.id = id
        self.kind = kind
        self.title = title
        self.body = body
        self.createdAt = createdAt
        self.isRead = isRead
    }
}
