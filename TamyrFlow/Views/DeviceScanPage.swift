import SwiftUI

struct DeviceScanPage: View {
    @EnvironmentObject private var vm: BluetoothViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    HStack(spacing: 12) {
                        statusPill(
                            title: L10n.Scan.bluetooth,
                            on: vm.bleService.isBluetoothOn,
                            onLabel: L10n.Scan.btOn,
                            offLabel: L10n.Scan.btOff
                        )
                        statusPill(
                            title: L10n.Scan.sdk,
                            on: vm.bleService.isSDKConfigured,
                            onLabel: L10n.Scan.sdkReady,
                            offLabel: L10n.Scan.sdkInit
                        )
                    }

                    TFCard(title: L10n.Scan.connection, subtitle: vm.statusText) {
                        Text(L10n.Scan.connectionHint)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.55))
                    }

                    HStack(spacing: 12) {
                        TFPrimaryButton(L10n.Scan.startScan, systemImage: "dot.radiowaves.left.and.right") {
                            vm.bleService.startScan()
                        }
                        TFSecondaryButton(L10n.Scan.stop) {
                            vm.bleService.stopScan()
                        }
                    }

                    ScanningBanner(isActive: vm.bleService.isScanning)

                    HStack(spacing: 12) {
                        TFSecondaryButton(L10n.Scan.refresh) {
                            vm.bleService.refreshBluetoothStateIfConfigured()
                            vm.bleService.configureSDKIfNeeded()
                        }
                        TFSecondaryButton(L10n.Scan.appSettings) {
                            vm.bleService.openAppSettings()
                        }
                    }

                    if !vm.bleService.bluetoothDiagnostic.isEmpty {
                        Text(vm.bleService.bluetoothDiagnostic)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.white.opacity(0.4))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }

                    Text(L10n.Scan.xpcHint)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.35))
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if vm.bleService.scannedDevices.isEmpty {
                        TFCard(title: L10n.Scan.devices, subtitle: L10n.Scan.noDevices) {
                            Image(systemName: "applewatch.side.right")
                                .font(.system(size: 44))
                                .foregroundStyle(.white.opacity(0.2))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 24)
                        }
                    } else {
                        ForEach(vm.bleService.scannedDevices) { device in
                            TFCard(title: device.name, subtitle: device.address.isEmpty ? L10n.Scan.unknownAddr : device.address) {
                                HStack {
                                    Label("\(device.rssi) dBm", systemImage: "wifi")
                                        .font(.caption)
                                        .foregroundStyle(.white.opacity(0.45))
                                    Spacer()
                                }
                                HStack(spacing: 12) {
                                    TFPrimaryButton(L10n.Scan.connect, systemImage: "link") {
                                        vm.bleService.connect(device)
                                    }
                                    TFSecondaryButton(L10n.Scan.disconnect) {
                                        vm.bleService.disconnect()
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(L10n.Scan.title)
            .navigationBarTitleDisplayMode(.large)
            .tfNavigationChrome()
            .onAppear {
                vm.bleService.configureSDKIfNeeded()
                vm.bleService.refreshBluetoothStateIfConfigured()
            }
        }
    }

    private func statusPill(title: String, on: Bool, onLabel: String, offLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.45))
            HStack(spacing: 6) {
                Circle()
                    .fill(on ? AppTheme.accent : AppTheme.danger.opacity(0.8))
                    .frame(width: 8, height: 8)
                Text(on ? onLabel : offLabel)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(AppTheme.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                }
        }
    }
}
