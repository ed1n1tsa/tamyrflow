import Combine
import Foundation

/// Local in-app notification inbox (not APNs). Persists read state in UserDefaults.
@MainActor
final class AppNotificationsStore: ObservableObject {
    static let shared = AppNotificationsStore()

    @Published private(set) var items: [AppNotificationItem] = []
    /// Explicit published count so bell badges refresh reliably.
    @Published private(set) var unreadCount: Int = 0

    private let defaultsKey = "tamyrflow.notifications.v1"

    private init() {
        load()
        // Drop first-release placeholder tips (welcome / measure / goal stubs) so an
        // empty inbox stays empty and the bell badge does not stay lit forever.
        let before = items.count
        items.removeAll { $0.kind == .system || $0.kind == .measure || $0.kind == .goal }
        if items.count != before {
            persist()
        }
        recomputeUnread()
    }

    func refreshContextual(
        watchConnected: Bool,
        deviceName: String?,
        lastSyncAt: Date?
    ) {
        var next = items
        var changed = false

        if watchConnected {
            let title = L10n.Notifications.watchConnectedTitle
            let body = String(
                format: L10n.Notifications.watchConnectedBody,
                deviceName?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty ?? "Tamyr Watch"
            )
            if upsertIfChanged(&next, kind: .watch, title: title, body: body) {
                changed = true
            }
        } else if next.contains(where: { $0.kind == .watch }) {
            // Only surface disconnect if we already had a watch-related item (avoid badge after clear).
            let title = L10n.Notifications.watchDisconnectedTitle
            let body = L10n.Notifications.watchDisconnectedBody
            if upsertIfChanged(&next, kind: .watch, title: title, body: body) {
                changed = true
            }
        }

        if let lastSyncAt {
            let f = DateFormatter()
            f.locale = Locale(identifier: LanguageStoreBootstrap.bundle.preferredLocalizations.first ?? "ru")
            f.dateFormat = "HH:mm"
            let title = L10n.Notifications.syncTitle
            let body = String(format: L10n.Notifications.syncBody, f.string(from: lastSyncAt))
            if upsertIfChanged(&next, kind: .sync, title: title, body: body) {
                changed = true
            }
        }

        guard changed else { return }
        items = next.sorted { $0.createdAt > $1.createdAt }
        recomputeUnread()
        persist()
    }

    func markRead(_ id: UUID) {
        guard let idx = items.firstIndex(where: { $0.id == id }) else { return }
        guard !items[idx].isRead else { return }
        items[idx].isRead = true
        recomputeUnread()
        persist()
    }

    func markAllRead() {
        guard items.contains(where: { !$0.isRead }) else { return }
        for i in items.indices { items[i].isRead = true }
        recomputeUnread()
        persist()
    }

    func clearAll() {
        guard !items.isEmpty else { return }
        items = []
        unreadCount = 0
        persist()
    }

    // MARK: - Private

    /// Updates an existing kind in place, or inserts a new unread item when content is new.
    @discardableResult
    private func upsertIfChanged(
        _ list: inout [AppNotificationItem],
        kind: AppNotificationKind,
        title: String,
        body: String
    ) -> Bool {
        if let idx = list.firstIndex(where: { $0.kind == kind }) {
            let old = list[idx]
            if old.title == title, old.body == body {
                return false
            }
            // Content changed → treat as fresh unread.
            list[idx] = AppNotificationItem(
                id: old.id,
                kind: kind,
                title: title,
                body: body,
                createdAt: Date(),
                isRead: false
            )
            return true
        }

        list.insert(
            AppNotificationItem(kind: kind, title: title, body: body, isRead: false),
            at: 0
        )
        return true
    }

    private func recomputeUnread() {
        unreadCount = items.reduce(0) { $0 + ($1.isRead ? 0 : 1) }
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
