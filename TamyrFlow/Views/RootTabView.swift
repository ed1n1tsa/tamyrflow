import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var vm: BluetoothViewModel
    @State private var tab: MainTab = .scan

    var body: some View {
        TabView(selection: $tab) {
            DeviceScanPage()
                .tabItem { Label(L10n.Tab.scan, systemImage: "antenna.radiowaves.left.and.right") }
                .tag(MainTab.scan)

            DashboardPage(selectedTab: $tab)
                .tabItem { Label(L10n.Tab.home, systemImage: "square.grid.2x2.fill") }
                .tag(MainTab.home)

            HeartRatePage()
                .tabItem { Label(L10n.Tab.heart, systemImage: "heart.fill") }
                .tag(MainTab.heart)

            OxygenPage()
                .tabItem { Label(L10n.Tab.spo2, systemImage: "lungs.fill") }
                .tag(MainTab.spo2)

            TemperaturePage()
                .tabItem { Label(L10n.Tab.temp, systemImage: "thermometer.medium") }
                .tag(MainTab.temp)

            VitalsPage()
                .tabItem { Label(L10n.Tab.vitals, systemImage: "heart.text.square.fill") }
                .tag(MainTab.vitals)

            ECGPage()
                .tabItem { Label(L10n.Tab.ecg, systemImage: "waveform.path.ecg") }
                .tag(MainTab.ecg)

            MicroTestPage()
                .tabItem { Label(L10n.Tab.micro, systemImage: "cross.case.fill") }
                .tag(MainTab.micro)

            SettingsPage()
                .tabItem { Label(L10n.Tab.settings, systemImage: "gearshape.fill") }
                .tag(MainTab.settings)
        }
        .toolbarBackground(.ultraThinMaterial, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .safeAreaInset(edge: .top, spacing: 0) {
            ConnectionStatusBar(ble: vm.bleService, health: vm.healthService)
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
            if let err = vm.healthService.lastError ?? vm.bleService.errorText {
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
                        .background {
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(AppTheme.danger.opacity(0.5), lineWidth: 1)
                        }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 88)
            }
        }
    }
}
