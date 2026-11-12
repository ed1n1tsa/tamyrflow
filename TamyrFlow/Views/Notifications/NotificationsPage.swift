import SwiftUI

/// In-app notifications inbox — Home / Profile bell destination.
struct NotificationsPage: View {
    @EnvironmentObject private var vm: BluetoothViewModel
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss

    @ObservedObject private var store = AppNotificationsStore.shared

    var body: some View {
        ZStack {
            ProfileSetupBackground()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 6)

                if store.items.isEmpty {
                    emptyState
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 10) {
                            ForEach(store.items) { item in
                                notificationRow(item)
                                    .onTapGesture { store.markRead(item.id) }
                            }
                        }
                        .padding(.horizontal, ProfileTheme.contentInset)
                        .padding(.top, 14)
                        .padding(.bottom, 32)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .id(language.code)
        .onAppear {
            let connected = vm.bleService.connectionStatus == .connected
                || vm.bleService.connectionStatus == .verified
            let name = vm.currentDeviceName
            store.refreshContextual(
                watchConnected: connected,
                deviceName: (name == "-" || name.isEmpty) ? nil : name,
                lastSyncAt: vm.healthService.lastDailySyncAt
            )
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Spacer()

            Text(L10n.Notifications.title)
                .font(AppFont.interBold(17))
                .foregroundStyle(.white)

            Spacer()

            Menu {
                Button(L10n.Notifications.markAllRead) { store.markAllRead() }
                Button(L10n.Notifications.clearAll, role: .destructive) { store.clearAll() }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Spacer()
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(ProfileTheme.accent)
            Text(L10n.Notifications.emptyTitle)
                .font(AppFont.interBold(18))
                .foregroundStyle(.white)
            Text(L10n.Notifications.emptyBody)
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 36)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private func notificationRow(_ item: AppNotificationItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(ProfileTheme.accent.opacity(item.isRead ? 0.12 : 0.22))
                    .frame(width: 44, height: 44)
                Image(systemName: item.kind.systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ProfileTheme.accent)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title)
                        .font(AppFont.interBold(15))
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    Spacer(minLength: 8)
                    Text(Self.relativeTime.localizedString(for: item.createdAt, relativeTo: Date()))
                        .font(AppFont.interBold(11))
                        .foregroundStyle(ProfileTheme.muted)
                }
                Text(item.body)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(Color.white.opacity(0.72))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if !item.isRead {
                Circle()
                    .fill(ProfileTheme.accent)
                    .frame(width: 8, height: 8)
                    .padding(.top, 6)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ProfileTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            item.isRead ? ProfileTheme.cardBorder.opacity(0.7) : ProfileTheme.accent.opacity(0.45),
                            lineWidth: 1
                        )
                )
        )
    }

    private static let relativeTime: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .short
        return f
    }()
}

/// Shared bell button used across Home / Profile / Indicators headers.
struct NotificationsBellButton: View {
    @ObservedObject private var store = AppNotificationsStore.shared
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(ProfileTheme.cardFill)
                            .overlay(Circle().strokeBorder(ProfileTheme.cardBorder, lineWidth: 1))
                    )
                if store.unreadCount > 0 {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .offset(x: -4, y: 4)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.Notifications.title)
    }
}
