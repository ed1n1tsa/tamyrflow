import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var vm: BluetoothViewModel
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var language: LanguageStore
    @State private var tab: MainTab = .home

    var body: some View {
        ZStack(alignment: .bottom) {
            // Keep tab roots alive so Activity/Goals don’t reset to empty on every switch.
            ZStack {
                DashboardPage(selectedTab: $tab, auth: auth)
                    .opacity(tab == .home ? 1 : 0)
                    .allowsHitTesting(tab == .home)
                IndicatorsPageView(auth: auth, isActive: tab == .metrics)
                    .opacity(tab == .metrics ? 1 : 0)
                    .allowsHitTesting(tab == .metrics)
                ActivityPageView(auth: auth, selectedTab: $tab)
                    .opacity(tab == .activity ? 1 : 0)
                    .allowsHitTesting(tab == .activity)
                GoalsPageView(auth: auth)
                    .opacity(tab == .goals ? 1 : 0)
                    .allowsHitTesting(tab == .goals)
                ProfilePage(selectedTab: $tab, auth: auth)
                    .opacity(tab == .profile ? 1 : 0)
                    .allowsHitTesting(tab == .profile)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.bottom, ProfileTheme.tabBarHeight + 18)

            FloatingTabBar(selection: $tab)
                .padding(.horizontal, 13)
                .padding(.bottom, 8)
        }
        // Observe language so tab titles and any child that reads L10n re-render.
        // Avoid `.id(language…)` on tab roots — it remounts Profile and pops Settings.
        .environment(\.locale, Locale(identifier: language.code.bundleCode))
        // Home has its own watch status card; other tabs don't need the legacy BLE strip.
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
        // Home/Indicators own their refreshable. Avoid a root refreshable — it also fires
        // inside pushed Pulse/Vital pages and briefly shows a sync/measure overlay.
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
    @EnvironmentObject private var language: LanguageStore

    var body: some View {
        let _ = language.revision
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

