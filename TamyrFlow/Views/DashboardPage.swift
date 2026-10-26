import SwiftUI

struct DashboardPage: View {
    @EnvironmentObject private var vm: BluetoothViewModel
    @EnvironmentObject private var auth: AuthService
    @Binding var selectedTab: MainTab

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TFCard(title: L10n.Dashboard.capsTitle, subtitle: L10n.Dashboard.capsSub) {
                        Text(L10n.Dashboard.capsBody)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    TFCard(title: L10n.Hub.section, subtitle: L10n.Hub.sectionSub) {
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            hubNav(title: L10n.Tab.heart, icon: "heart.fill") {
                                PulsePageView(auth: auth, health: vm.healthService, ble: vm.bleService)
                            }
                            hubNav(title: L10n.Tab.spo2, icon: "lungs.fill") { OxygenPage() }
                            hubNav(title: L10n.Tab.temp, icon: "thermometer.medium") { TemperaturePage() }
                            hubNav(title: L10n.Tab.ecg, icon: "waveform.path.ecg") { ECGPage() }
                            hubNav(title: L10n.Tab.micro, icon: "cross.case.fill") { MicroTestPage() }
                            hubNav(title: L10n.Hub.vitals, icon: "heart.text.square.fill") { VitalsPage() }
                            hubNav(title: L10n.Tab.scan, icon: "antenna.radiowaves.left.and.right") { DeviceScanPage() }
                            Button {
                                selectedTab = .metrics
                            } label: {
                                hubLabel(title: L10n.Tab.metrics, icon: "chart.bar.fill")
                            }
                            .buttonStyle(.plain)
                        }

                        VStack(spacing: 10) {
                            TFSecondaryButton(L10n.Hub.steps) {
                                Task {
                                    let totals = await vm.healthService.fetchRealtimeStepTotals()
                                    await WatchMetricsBridge.persistBandDayTotals(
                                        auth: auth,
                                        steps: totals.steps,
                                        caloriesKcal: totals.caloriesKcal,
                                        sleepMinutes: nil
                                    )
                                }
                            }
                            TFSecondaryButton(L10n.Hub.sleep) {
                                Task {
                                    if let minutes = await vm.healthService.fetchSleepMinutesRobust(), minutes > 0 {
                                        await WatchMetricsBridge.persistBandDayTotals(
                                            auth: auth,
                                            steps: nil,
                                            caloriesKcal: nil,
                                            sleepMinutes: minutes
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.top, 6)
                    }

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        miniStat(title: L10n.Dashboard.battery, value: vm.batteryText, icon: "battery.100.bolt")
                        miniStat(title: L10n.Dashboard.charge, value: vm.chargeStateText, icon: "bolt.fill")
                        miniStat(title: L10n.Dashboard.device, value: vm.currentDeviceName == "-" ? "—" : String(vm.currentDeviceName.prefix(10)), icon: "applewatch")
                        miniStat(title: L10n.Dashboard.sdk, value: vm.bleService.isSDKConfigured ? L10n.Dashboard.sdkOk : L10n.Dashboard.sdkWait, icon: "cpu")
                        miniStat(title: L10n.Hub.steps, value: stepsValue, icon: "figure.walk")
                        miniStat(title: L10n.Hub.sleep, value: sleepValue, icon: "moon.zzz.fill")
                    }

                    TFCard(title: L10n.Dashboard.liveTraces, subtitle: L10n.Dashboard.liveSub) {
                        LiveMetricChart(
                            title: L10n.Dashboard.heartRate,
                            data: vm.healthService.heartRateHistory,
                            unit: "bpm",
                            color: Color.pink
                        )
                        Divider().background(Color.white.opacity(0.12))
                        LiveMetricChart(
                            title: L10n.Dashboard.spo2,
                            data: vm.healthService.oxygenHistory,
                            unit: "%",
                            color: AppTheme.accentSecondary
                        )
                    }

                    TFCard(title: L10n.Dashboard.syncProgress, subtitle: L10n.Dashboard.syncSub) {
                        LiveMetricChart(
                            title: L10n.Dashboard.progressPct,
                            data: vm.healthService.syncProgressHistory,
                            unit: "%",
                            color: AppTheme.accent,
                            yDomain: 0...100
                        )
                        Text(vm.healthService.readProgressText)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.45))
                    }

                    TFCard(title: L10n.Dashboard.deviceCard, subtitle: vm.currentDeviceAddress) {
                        LabeledContent(L10n.Dashboard.name) {
                            Text(vm.currentDeviceName)
                                .foregroundStyle(.white)
                        }
                        .foregroundStyle(.white.opacity(0.55))
                        LabeledContent(L10n.Dashboard.status) {
                            Text(vm.statusText)
                                .foregroundStyle(AppTheme.accent)
                        }
                        .foregroundStyle(.white.opacity(0.55))
                    }

                    TFCard(title: L10n.Dashboard.actions, subtitle: L10n.Dashboard.actionsSub) {
                        TFPrimaryButton(L10n.Dashboard.readBattery, systemImage: "battery.100") {
                            vm.bleService.readBattery()
                        }
                        TFPrimaryButton(L10n.Dashboard.syncTime, systemImage: "clock.arrow.circlepath") {
                            vm.healthService.syncTime()
                        }
                        .padding(.top, 4)
                        TFSecondaryButton(L10n.Dashboard.readDaily) {
                            vm.healthService.readAllDailyData()
                        }
                    }

                    TFCard(title: L10n.Dashboard.pipeline, subtitle: L10n.Dashboard.pipelineSub) {
                        HStack {
                            Label(vm.healthService.operation.localizedLabel, systemImage: "arrow.triangle.2.circlepath")
                                .font(.caption.weight(.medium))
                            Spacer()
                            Text(vm.healthService.canRunManualTests ? L10n.Dashboard.manualOk : L10n.Dashboard.busy)
                                .font(.caption)
                                .foregroundStyle(vm.healthService.canRunManualTests ? AppTheme.accent : AppTheme.warning)
                        }
                        .foregroundStyle(.white.opacity(0.75))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .refreshable {
                await vm.performPullToRefresh(auth: auth)
            }
            .navigationTitle(L10n.Dashboard.title)
            .navigationBarTitleDisplayMode(.large)
            .tfNavigationChrome()
        }
    }

    private var stepsValue: String {
        if let s = vm.healthService.todaySteps { return "\(s)" }
        return "—"
    }

    private var sleepValue: String {
        if let minutes = vm.healthService.todaySleepMinutes, minutes > 0 {
            let hours = Double(minutes) / 60.0
            return String(format: "%.1fh", hours)
        }
        if let n = vm.healthService.sleepSegmentsToday { return "\(n)" }
        return "—"
    }

    private func hubNav<Dest: View>(title: String, icon: String, @ViewBuilder destination: () -> Dest) -> some View {
        NavigationLink {
            destination()
        } label: {
            hubLabel(title: title, icon: icon)
        }
        .buttonStyle(.plain)
    }

    private func hubLabel(title: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.45))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .topLeading)
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                }
        }
    }

    private func miniStat(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(AppTheme.accent)
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.45))
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppTheme.cardBackground)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                }
        }
    }
}
