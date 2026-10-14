import SwiftUI

/// Multi-step watch pairing: prep → scan → connecting → permissions → success.
struct WatchConnectFlowView: View {
    @EnvironmentObject private var vm: BluetoothViewModel
    @EnvironmentObject private var language: LanguageStore
    var onFinished: () -> Void

    @StateObject private var permissions = WatchPermissionService()
    @State private var step = 1
    @State private var selectedDevice: ScanDevice?
    @State private var connectPhase = 0
    @State private var permissionBusy = false

    private var isLinked: Bool {
        vm.bleService.connectionStatus == .connected
            || vm.bleService.connectionStatus == .verified
    }

    var body: some View {
        ZStack {
            ProfileSetupBackground()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 8)

                Group {
                    switch step {
                    case 1: prepStep
                    case 2: scanStep
                    case 3: connectingStep
                    case 4: permissionsStep
                    default: successStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            }
        }
        .id(language.code)
        .onAppear {
            vm.bleService.configureSDKIfNeeded()
            permissions.refreshBluetooth(
                isOn: vm.bleService.isBluetoothOn,
                sdkConfigured: vm.bleService.isSDKConfigured
            )
        }
        .onChange(of: vm.bleService.isBluetoothOn) { _, on in
            permissions.refreshBluetooth(isOn: on, sdkConfigured: vm.bleService.isSDKConfigured)
        }
        .onChange(of: vm.bleService.connectionStatus) { _, status in
            if step == 3 {
                advanceConnectPhases(for: status)
            }
        }
        .onChange(of: vm.bleService.scannedDevices.count) { _, _ in
            // keep UI live
        }
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack {
            Button {
                if step <= 1 || step >= 5 {
                    cleanupAndDismiss()
                } else if step == 2 {
                    vm.bleService.stopScan()
                    step = 1
                } else if step == 3 {
                    // stay / allow back to scan
                    step = 2
                    vm.bleService.startScan()
                } else {
                    step -= 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Spacer()
            Text(stepTitle)
                .font(AppFont.interBold(17))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
    }

    private var stepTitle: String {
        switch step {
        case 1: return L10n.Watch.flowTitle
        case 2: return L10n.Watch.flowSearchTitle
        case 3: return L10n.Watch.flowConnectingTitle
        case 4: return L10n.Watch.flowPermissionsTitle
        default: return L10n.Watch.flowSuccessTitle
        }
    }

    // MARK: - Step 1 Prep

    private var prepStep: some View {
        VStack(spacing: 18) {
            Text(L10n.Watch.prepHeadline)
                .font(AppFont.interBold(24))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(L10n.Watch.prepSub)
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image("WatchPowerOn")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 200)
                .padding(.vertical, 8)

            VStack(spacing: 10) {
                prepRow(systemImage: "power", text: L10n.Watch.prepPower)
                prepRow(systemImage: "antenna.radiowaves.left.and.right", text: L10n.Watch.prepBluetooth)
                prepRow(systemImage: "location.fill", text: L10n.Watch.prepNearby)
            }

            Spacer()

            Button {
                vm.bleService.configureSDKIfNeeded()
                vm.bleService.startScan()
                step = 2
            } label: {
                Text(L10n.Activity.continueCTA)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Capsule().fill(ProfileTheme.accent))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, ProfileTheme.contentInset)
        .padding(.top, 16)
    }

    private func prepRow(systemImage: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(ProfileTheme.accent)
                .frame(width: 36, height: 36)
                .background(Circle().fill(ProfileTheme.accent.opacity(0.18)))
            Text(text)
                .font(AppFont.interBold(14))
                .foregroundStyle(.white)
            Spacer()
        }
        .padding(14)
        .profileCard()
    }

    // MARK: - Step 2 Scan

    private var scanStep: some View {
        VStack(spacing: 16) {
            Text(L10n.Watch.searchHeadline)
                .font(AppFont.interBold(22))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(L10n.Watch.searchSub)
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)

            WatchSearchAnimationView(isAnimating: vm.bleService.isScanning)
                .padding(.vertical, 8)

            HStack {
                Text(L10n.Watch.foundDevices)
                    .font(AppFont.interBold(15))
                    .foregroundStyle(.white)
                Spacer()
                Button {
                    vm.bleService.startScan()
                } label: {
                    Image(systemName: "arrow.clockwise")
                        .foregroundStyle(ProfileTheme.accent)
                }
                .buttonStyle(.plain)
            }

            ScrollView {
                VStack(spacing: 10) {
                    if vm.bleService.scannedDevices.isEmpty {
                        Text(vm.bleService.isScanning ? L10n.Watch.searching : L10n.Scan.noDevices)
                            .font(AppFont.interBold(13))
                            .foregroundStyle(ProfileTheme.muted)
                            .padding(.vertical, 20)
                    } else {
                        ForEach(vm.bleService.scannedDevices) { device in
                            Button {
                                selectedDevice = device
                                vm.bleService.connect(device)
                                connectPhase = 0
                                step = 3
                            } label: {
                                HStack(spacing: 12) {
                                    Image("WatchIconFaces")
                                        .resizable().scaledToFit().frame(width: 40, height: 40)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(device.name)
                                            .font(AppFont.interBold(15))
                                            .foregroundStyle(.white)
                                        Text(device.address.isEmpty ? L10n.Scan.unknownAddr : device.address)
                                            .font(AppFont.interBold(11))
                                            .foregroundStyle(ProfileTheme.muted)
                                    }
                                    Spacer()
                                    Text("\(device.rssi)")
                                        .font(AppFont.interBold(12))
                                        .foregroundStyle(ProfileTheme.accent)
                                }
                                .padding(12)
                                .profileCard()
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            Button {
                // tip
            } label: {
                Text(L10n.Watch.dontSeeWatch)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.accent)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 16)
        }
        .padding(.horizontal, ProfileTheme.contentInset)
        .padding(.top, 16)
        .onDisappear {
            if step != 3 { vm.bleService.stopScan() }
        }
    }

    // MARK: - Step 3 Connecting

    private var connectingStep: some View {
        VStack(spacing: 20) {
            Text(L10n.Watch.connectingHeadline)
                .font(AppFont.interBold(22))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(L10n.Watch.connectingSub)
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 200, height: 200)
                Circle()
                    .trim(from: 0, to: CGFloat(min(1, Double(connectPhase + 1) / 5.0)))
                    .stroke(ProfileTheme.accent, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 200, height: 200)
                Image("WatchConnecting")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 140, height: 140)
            }
            .padding(.vertical, 12)

            VStack(alignment: .leading, spacing: 12) {
                connectRow(0, L10n.Watch.phaseFound)
                connectRow(1, L10n.Watch.phaseLink)
                connectRow(2, L10n.Watch.phasePermissions)
                connectRow(3, L10n.Watch.phaseSync)
                connectRow(4, L10n.Watch.phaseFinish)
            }

            if vm.bleService.connectionStatus == .failed || vm.bleService.connectionStatus == .timeout {
                Text(L10n.Watch.connectFailed)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(AppTheme.danger)
                Button {
                    step = 2
                    vm.bleService.startScan()
                } label: {
                    Text(L10n.Watch.retry)
                        .font(AppFont.interBold(15))
                        .foregroundStyle(ProfileTheme.accent)
                }
                .buttonStyle(.plain)
            }

            Spacer()
        }
        .padding(.horizontal, ProfileTheme.contentInset)
        .padding(.top, 16)
    }

    private func connectRow(_ index: Int, _ title: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                if connectPhase > index {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(ProfileTheme.accent)
                } else if connectPhase == index {
                    ProgressView().tint(ProfileTheme.accent)
                } else {
                    Circle()
                        .stroke(ProfileTheme.cardBorder, lineWidth: 2)
                        .frame(width: 22, height: 22)
                }
            }
            .frame(width: 28, height: 28)
            Text(title)
                .font(AppFont.interBold(14))
                .foregroundStyle(connectPhase >= index ? .white : ProfileTheme.muted)
            Spacer()
        }
    }

    private func advanceConnectPhases(for status: DeviceConnectionStatus) {
        switch status {
        case .connecting:
            connectPhase = max(connectPhase, 1)
        case .connected:
            connectPhase = max(connectPhase, 2)
            // Move to permissions after short beat
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                if step == 3 { step = 4 }
            }
        case .verified:
            connectPhase = 4
            Task {
                try? await Task.sleep(nanoseconds: 400_000_000)
                if step == 3 { step = 4 }
            }
        case .failed, .timeout:
            break
        case .disconnected:
            break
        }
    }

    // MARK: - Step 4 Permissions

    private var permissionsStep: some View {
        VStack(spacing: 16) {
            Text(L10n.Watch.permissionsHeadline)
                .font(AppFont.interBold(22))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(L10n.Watch.permissionsSub)
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 10) {
                ForEach(WatchPermissionService.Kind.allCases) { kind in
                    permissionRow(kind)
                }
            }

            Spacer()

            Button {
                Task {
                    permissionBusy = true
                    await permissions.requestAll {
                        vm.bleService.configureSDKIfNeeded()
                        permissions.refreshBluetooth(
                            isOn: vm.bleService.isBluetoothOn,
                            sdkConfigured: vm.bleService.isSDKConfigured
                        )
                    }
                    permissionBusy = false
                    if isLinked || permissions.allGrantedOrUnavailable {
                        connectPhase = 4
                        step = 5
                        // Fire-and-forget battery; never block this button on SDK callback.
                        Task { await vm.bleService.readBatteryAsync() }
                    }
                }
            } label: {
                Text(L10n.Activity.continueCTA)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        Capsule().fill(
                            permissionBusy ? ProfileTheme.accent.opacity(0.4) : ProfileTheme.accent
                        )
                    )
            }
            .buttonStyle(.plain)
            .disabled(permissionBusy)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, ProfileTheme.contentInset)
        .padding(.top, 16)
        .task {
            // Auto-kick first request sequence lightly
            permissions.refreshBluetooth(
                isOn: vm.bleService.isBluetoothOn,
                sdkConfigured: vm.bleService.isSDKConfigured
            )
        }
    }

    private func permissionRow(_ kind: WatchPermissionService.Kind) -> some View {
        let status = permissions.statuses[kind] ?? .pending
        return Button {
            Task {
                await permissions.request(kind) {
                    vm.bleService.configureSDKIfNeeded()
                    permissions.refreshBluetooth(
                        isOn: vm.bleService.isBluetoothOn,
                        sdkConfigured: vm.bleService.isSDKConfigured
                    )
                }
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: permissionSymbol(kind))
                    .foregroundStyle(ProfileTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(ProfileTheme.accent.opacity(0.18)))
                VStack(alignment: .leading, spacing: 3) {
                    Text(permissionTitle(kind))
                        .font(AppFont.interBold(14))
                        .foregroundStyle(.white)
                    Text(permissionSub(kind))
                        .font(AppFont.interBold(11))
                        .foregroundStyle(ProfileTheme.muted)
                }
                Spacer()
                statusIcon(status)
            }
            .padding(12)
            .profileCard()
        }
        .buttonStyle(.plain)
    }

    private func statusIcon(_ status: WatchPermissionService.Status) -> some View {
        Group {
            switch status {
            case .granted:
                Image(systemName: "checkmark.circle.fill").foregroundStyle(Color.green)
            case .denied:
                Image(systemName: "xmark.circle.fill").foregroundStyle(AppTheme.danger)
            case .unavailable:
                Image(systemName: "minus.circle.fill").foregroundStyle(ProfileTheme.muted)
            case .pending:
                Circle().stroke(ProfileTheme.cardBorder, lineWidth: 2).frame(width: 22, height: 22)
            }
        }
    }

    // MARK: - Step 5 Success

    private var successStep: some View {
        VStack(spacing: 18) {
            Text(L10n.Watch.flowSuccessTitle)
                .font(AppFont.interBold(26))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(L10n.Watch.successSub)
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)

            Image("WatchSuccess")
                .resizable()
                .scaledToFit()
                .frame(maxHeight: 220)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 10) {
                successRow(L10n.Watch.phaseLink)
                successRow(L10n.Watch.phasePermissions)
                successRow(L10n.Watch.phaseSync)
                successRow(L10n.Watch.phaseFinish)
            }

            Spacer()

            Button {
                cleanupAndDismiss()
            } label: {
                Text(L10n.Watch.goToMyWatch)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Capsule().fill(ProfileTheme.accent))
            }
            .buttonStyle(.plain)

            Button {
                cleanupAndDismiss()
            } label: {
                Text(L10n.Watch.setupLater)
                    .font(AppFont.interBold(15))
                    .foregroundStyle(ProfileTheme.accent)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Capsule().strokeBorder(ProfileTheme.accent, lineWidth: 1.2))
            }
            .buttonStyle(.plain)
            .padding(.bottom, 20)
        }
        .padding(.horizontal, ProfileTheme.contentInset)
        .padding(.top, 16)
    }

    private func successRow(_ title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.green)
            Text(title)
                .font(AppFont.interBold(14))
                .foregroundStyle(.white)
            Spacer()
        }
    }

    // MARK: - Helpers

    private func cleanupAndDismiss() {
        vm.bleService.stopScan()
        onFinished()
        // Heavy daily dump / DB read after leaving this screen — avoids freezing success UI.
        vm.scheduleDeferredStepsSleepSync()
    }

    private func permissionSymbol(_ kind: WatchPermissionService.Kind) -> String {
        switch kind {
        case .bluetooth: return "antenna.radiowaves.left.and.right"
        case .notifications: return "bell.fill"
        case .health: return "heart.fill"
        case .location: return "location.fill"
        }
    }

    private func permissionTitle(_ kind: WatchPermissionService.Kind) -> String {
        switch kind {
        case .bluetooth: return L10n.Watch.permBluetooth
        case .notifications: return L10n.Watch.permNotifications
        case .health: return L10n.Watch.permHealth
        case .location: return L10n.Watch.permLocation
        }
    }

    private func permissionSub(_ kind: WatchPermissionService.Kind) -> String {
        switch kind {
        case .bluetooth: return L10n.Watch.permBluetoothSub
        case .notifications: return L10n.Watch.permNotificationsSub
        case .health: return L10n.Watch.permHealthSub
        case .location: return L10n.Watch.permLocationSub
        }
    }
}
