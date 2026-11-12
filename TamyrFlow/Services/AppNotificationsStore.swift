import Combine
import Foundation

/// Local in-app notification inbox (not APNs). Persists read state in UserDefaults.
@MainActor
final class AppNotificationsStore: ObservableObject {
    static let shared = AppNotificationsStore()

    @Published private(set) var items: [AppNotificationItem] = []

    private let defaultsKey = "tamyrflow.notifications.v1"

    var unreadCount: Int { items.filter { !$0.isRead }.count }

    private init() {
        load()
        if items.isEmpty {
            seedDefaults()
        }
    }

    func refreshContextual(
        watchConnected: Bool,
        deviceName: String?,
        lastSyncAt: Date?
    ) {
        var next = items

        if watchConnected {
            let title = L10n.Notifications.watchConnectedTitle
            let body = String(
                format: L10n.Notifications.watchConnectedBody,
                deviceName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Tamyr Watch"
            )
            upsert(&next, kind: .watch, title: title, body: body)
        } else {
            upsert(
                &next,
                kind: .watch,
                title: L10n.Notifications.watchDisconnectedTitle,
                body: L10n.Notifications.watchDisconnectedBody
            )
        }

        if let lastSyncAt {
            let f = DateFormatter()
            f.locale = Locale(identifier: LanguageStoreBootstrap.bundle.preferredLocalizations.first ?? "ru")
            f.dateFormat = "HH:mm"
            upsert(
                &next,
                kind: .sync,
                title: L10n.Notifications.syncTitle,
                body: String(format: L10n.Notifications.syncBody, f.string(from: lastSyncAt))
            )
        }

        upsert(
            &next,
            kind: .measure,
            title: L10n.Notifications.measureTitle,
            body: L10n.Notifications.measureBody
        )
        upsert(
            &next,
            kind: .goal,
            title: L10n.Notifications.goalTitle,
            body: L10n.Notifications.goalBody
        )

        items = next.sorted { $0.createdAt > $1.createdAt }
        persist()
    }

    func markRead(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        items[idx].isRead = true
        persist()
    }

    func markAllRead() {
        for i in items.indices { items[i].isRead = true }
        persist()
    }

    func clearAll() {
        items = []
        persist()
    }

    // MARK: - Private

    private func seedDefaults() {
        items = [
            AppNotificationItem(
                kind: .system,
                title: L10n.Notifications.welcomeTitle,
                body: L10n.Notifications.welcomeBody,
                createdAt: Date().addingTimeInterval(-3600)
            ),
            AppNotificationItem(
                kind: .measure,
                title: L10n.Notifications.measureTitle,
                body: L10n.Notifications.measureBody,
                createdAt: Date().addingTimeInterval(-7200)
            ),
            AppNotificationItem(
                kind: .goal,
                title: L10n.Notifications.goalTitle,
                body: L10n.Notifications.goalBody,
                createdAt: Date().addingTimeInterval(-10_800)
            )
        ]
        persist()
    }

    private func upsert(
        _ list: inout [AppNotificationItem],
        kind: AppNotificationKind,
        title: String,
        body: String
    ) {
        if let idx = list.firstIndex(where: { $0.kind == kind && $0.title == title }) {
            list[idx] = AppNotificationItem(
                id: list[idx].id,
                kind: kind,
                title: title,
                body: body,
                createdAt: list[idx].createdAt,
                isRead: list[idx].isRead
            )
        } else {
            list.insert(
                AppNotificationItem(kind: kind, title: title, body: body),
                at: 0
            )
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: defaultsKey) else { return }
        if let decoded = try? JSONDecoder().decode([AppNotificationItem].self, from: data) {
            items = decoded.sorted { $0.createdAt > $1.createdAt }
        }
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: defaultsKey)
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
