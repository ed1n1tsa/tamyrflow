import SwiftUI
import VeepooBleSDK

struct MyWatchPage: View {
    @EnvironmentObject private var vm: BluetoothViewModel
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss

    @State private var showConnectFlow = false
    @State private var stubAlert: String?
    @State private var lastSyncText: String = ""

    private var isConnected: Bool {
        vm.bleService.connectionStatus == .connected
            || vm.bleService.connectionStatus == .verified
    }

    private var deviceName: String {
        vm.bleService.connectedDevice?.deviceName ?? "SyncWatch Pro"
    }

    private var batteryPercent: Int? {
        vm.bleService.batteryInfo.map(\.battery)
    }

    var body: some View {
        ZStack {
            ProfileSetupBackground()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        deviceCard
                        statusBanner
                        functionsSection
                        settingsSection
                    }
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationBarHidden(true)
        .id(language.code)
        .onAppear {
            vm.bleService.configureSDKIfNeeded()
            refreshSyncLabel()
            if isConnected {
                // Battery only — do not start Veepoo daily dump here (crashes some bands).
                Task { await vm.bleService.readBatteryAsync() }
            }
        }
        .onChange(of: isConnected) { _, on in
            if on {
                refreshSyncLabel()
                Task { await vm.bleService.readBatteryAsync() }
            }
        }
        .fullScreenCover(isPresented: $showConnectFlow) {
            WatchConnectFlowView {
                showConnectFlow = false
            }
            .environmentObject(vm)
            .environmentObject(language)
        }
        .alert(L10n.Profile.stubTitle, isPresented: Binding(
            get: { stubAlert != nil },
            set: { if !$0 { stubAlert = nil } }
        )) {
            Button(L10n.Goals.ok, role: .cancel) {}
        } message: {
            Text(stubAlert ?? "")
        }
    }

    // MARK: - Chrome

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
            Text(L10n.Watch.screenTitle)
                .font(AppFont.interBold(17))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
    }

    // MARK: - Device card

    private var deviceCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                Image("ProfileWatch")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 80)

                VStack(alignment: .leading, spacing: 8) {
                    Text(deviceName)
                        .font(AppFont.interBold(18))
                        .foregroundStyle(.white)
                        .lineLimit(1)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(isConnected ? ProfileTheme.connected : AppTheme.danger)
                            .frame(width: 8, height: 8)
                        Text(isConnected ? L10n.Profile.connected : L10n.Profile.disconnected)
                            .font(AppFont.interBold(13))
                            .foregroundStyle(.white.opacity(0.85))
                    }

                    if isConnected {
                        Button {
                            vm.bleService.disconnect()
                        } label: {
                            Text(L10n.Watch.disconnect)
                                .font(AppFont.interBold(14))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Capsule().fill(ProfileTheme.accent))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            showConnectFlow = true
                        } label: {
                            Text(L10n.Watch.connect)
                                .font(AppFont.interBold(14))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(Capsule().fill(ProfileTheme.accent))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            rowSync
            rowBattery
        }
        .padding(16)
        .profileCard()
    }

    private var rowSync: some View {
        Button {
            stubAlert = L10n.Profile.stubBody
        } label: {
            HStack(spacing: 12) {
                Image("WatchIconSync")
                    .resizable().scaledToFit().frame(width: 32, height: 32)
                Text(L10n.Watch.lastSync)
                    .font(AppFont.interBold(14))
                    .foregroundStyle(.white)
                Spacer()
                Text(lastSyncText.isEmpty ? "—" : lastSyncText)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.muted)
                Image(systemName: "chevron.right")
                    .foregroundStyle(ProfileTheme.muted)
            }
        }
        .buttonStyle(.plain)
    }

    private var rowBattery: some View {
        HStack(spacing: 12) {
            Image("WatchIconBattery")
                .resizable().scaledToFit().frame(width: 32, height: 32)
            Text(L10n.Watch.battery)
                .font(AppFont.interBold(14))
                .foregroundStyle(.white)
            Spacer()
            if let batteryPercent {
                Text("\(batteryPercent)%")
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.muted)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.12))
                        Capsule()
                            .fill(Color.green)
                            .frame(width: geo.size.width * CGFloat(batteryPercent) / 100)
                    }
                }
                .frame(width: 72, height: 6)
            } else {
                Text(isConnected ? "…" : "—")
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.muted)
            }
        }
    }

    // MARK: - Banner

    private var statusBanner: some View {
        HStack(spacing: 14) {
            Image(isConnected ? "WatchSuccess" : "WatchBannerPhoneWatch")
                .resizable()
                .scaledToFit()
                .frame(width: 72, height: 56)

            VStack(alignment: .leading, spacing: 6) {
                Text(isConnected ? L10n.Watch.bannerConnectedTitle : L10n.Watch.bannerDisconnectedTitle)
                    .font(AppFont.interBold(15))
                    .foregroundStyle(.white)
                Text(isConnected ? L10n.Watch.bannerConnectedSub : L10n.Watch.bannerDisconnectedSub)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(14)
        .profileCard()
    }

    // MARK: - Functions / settings stubs

    private var functionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Watch.functionsTitle)
                .font(AppFont.interBold(16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Fixed equal cells so columns/rows stay level.
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    stubFeature(asset: "GoalIconSteps", title: L10n.Watch.featActivity, sub: L10n.Watch.featActivitySub)
                    stubFeature(systemImage: "heart.fill", tint: .red, title: L10n.Watch.featHeart, sub: L10n.Watch.featHeartSub)
                }
                GridRow {
                    stubFeature(asset: "GoalIconSleep", title: L10n.Watch.featSleep, sub: L10n.Watch.featSleepSub)
                    stubFeature(asset: "GoalIconWater", title: L10n.Watch.featWater, sub: L10n.Watch.featWaterSub)
                }
            }
        }
    }

    private func stubFeature(asset: String? = nil, systemImage: String? = nil, tint: Color = ProfileTheme.accent, title: String, sub: String) -> some View {
        Button { stubAlert = L10n.Profile.stubBody } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    if let asset {
                        Image(asset).resizable().scaledToFit().frame(width: 36, height: 36)
                    } else if let systemImage {
                        Image(systemName: systemImage)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(tint)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(tint.opacity(0.18)))
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(ProfileTheme.muted)
                }
                .frame(height: 36)

                Text(title)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 34, alignment: .topLeading)

                Text(sub)
                    .font(AppFont.interBold(11))
                    .foregroundStyle(ProfileTheme.muted)
                    .multilineTextAlignment(.leading)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, minHeight: 30, alignment: .topLeading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
            .profileCard()
        }
        .buttonStyle(.plain)
        .gridCellUnsizedAxes([.vertical])
    }

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.Watch.settingsTitle)
                .font(AppFont.interBold(16))
                .foregroundStyle(.white)

            VStack(spacing: 0) {
                settingsRow(asset: "WatchIconFaces", title: L10n.Watch.setFaces, sub: nil)
                divider
                settingsRow(asset: "WatchIconBell", title: L10n.Watch.setNotifications, sub: L10n.Watch.setNotificationsSub)
                divider
                settingsRow(asset: "WatchIconSettings", title: L10n.Watch.setSync, sub: L10n.Watch.setSyncSub)
                divider
                settingsRow(asset: "WatchIconMore", title: L10n.Watch.setMore, sub: L10n.Watch.setMoreSub)
            }
            .profileCard()
        }
    }

    private var divider: some View {
        Rectangle().fill(ProfileTheme.rowDivider).frame(height: 0.5).padding(.leading, 58)
    }

    private func settingsRow(asset: String, title: String, sub: String?) -> some View {
        Button { stubAlert = L10n.Profile.stubBody } label: {
            HStack(spacing: 12) {
                Image(asset).resizable().scaledToFit().frame(width: 36, height: 36)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(AppFont.interBold(14))
                        .foregroundStyle(.white)
                    if let sub {
                        Text(sub)
                            .font(AppFont.interBold(11))
                            .foregroundStyle(ProfileTheme.muted)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(ProfileTheme.muted)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func refreshSyncLabel() {
        let f = DateFormatter()
        f.locale = Locale(identifier: LanguageStoreBootstrap.bundle.preferredLocalizations.first ?? "ru")
        f.dateFormat = "HH:mm"
        if isConnected {
            lastSyncText = String(format: L10n.Watch.todayTime, f.string(from: Date()))
        } else {
            lastSyncText = L10n.Watch.neverSynced
        }
    }
}
