import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var vm: BluetoothViewModel
    @State private var tab: MainTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            Group {
                switch tab {
                case .home:
                    DashboardPage(selectedTab: $tab)
                case .metrics:
                    HeartRatePage()
                case .activity:
                    PlaceholderHubPage(
                        title: L10n.Tab.activity,
                        subtitle: L10n.Placeholder.activitySub,
                        systemImage: "figure.run"
                    )
                case .goals:
                    PlaceholderHubPage(
                        title: L10n.Tab.goals,
                        subtitle: L10n.Placeholder.goalsSub,
                        systemImage: "trophy.fill"
                    )
                case .profile:
                    ProfilePage()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, ProfileTheme.tabBarHeight + 18)

            FloatingTabBar(selection: $tab)
                .padding(.horizontal, 13)
                .padding(.bottom, 8)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if tab != .profile {
                ConnectionStatusBar(ble: vm.bleService, health: vm.healthService)
            }
        }
        .overlay {
            if let hud = vm.healthService.measurementHUD {
                MeasurementHUDView(state: hud) {
                    vm.healthService.dismissMeasurementOverlay()
                }
                .transition(.opacity)
                .zIndex(2000)
            }
        }
        .animation(.easeOut(duration: 0.2), value: vm.healthService.measurementHUD != nil)
        .refreshable {
            await vm.performPullToRefresh()
        }
        .overlay(alignment: .bottom) {
            if let err = vm.healthService.lastError ?? vm.bleService.errorText, tab != .profile {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(AppTheme.warning)
                    Text(err)
                        .font(.footnote.weight(.medium))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(AppTheme.danger.opacity(0.35))
                }
                .padding(.horizontal, 16)
                .padding(.bottom, ProfileTheme.tabBarHeight + 24)
            }
        }
    }
}

private struct FloatingTabBar: View {
    @Binding var selection: MainTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                Button {
                    selection = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.systemImage)
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 36, height: 28)
                            .background {
                                if selection == tab {
                                    Capsule(style: .continuous)
                                        .fill(ProfileTheme.accent)
                                }
                            }
                        Text(title(for: tab))
                            .font(AppFont.interBold(10))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(selection == tab ? .white : ProfileTheme.muted)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 8)
        .frame(height: ProfileTheme.tabBarHeight)
        .background {
            Capsule(style: .continuous)
                .fill(Color(red: 0.02, green: 0.08, blue: 0.18).opacity(0.94))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(ProfileTheme.cardBorder, lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 16, y: 4)
        }
    }

    private func title(for tab: MainTab) -> String {
        switch tab {
        case .home: return L10n.Tab.home
        case .metrics: return L10n.Tab.metrics
        case .activity: return L10n.Tab.activity
        case .goals: return L10n.Tab.goals
        case .profile: return L10n.Tab.profile
        }
    }
}

struct PlaceholderHubPage: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        ZStack {
            ProfileSetupBackground()
            VStack(spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(ProfileTheme.accent)
                Text(title)
                    .font(AppFont.interBold(24))
                    .foregroundStyle(.white)
                Text(subtitle)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
            }
        }
    }
}
