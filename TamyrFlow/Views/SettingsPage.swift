import SwiftUI

struct SettingsPage: View {
    @EnvironmentObject private var vm: BluetoothViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TFCard(title: L10n.Settings.profile, subtitle: L10n.Settings.profileSub) {
                        VStack(spacing: 12) {
                            field(L10n.Settings.height, text: $vm.height)
                            field(L10n.Settings.weight, text: $vm.weight)
                            field(L10n.Settings.age, text: $vm.age)
                            Picker(L10n.Settings.sex, selection: $vm.sex) {
                                Text(L10n.Settings.female).tag(0)
                                Text(L10n.Settings.male).tag(1)
                            }
                            .pickerStyle(.segmented)
                            field(L10n.Settings.targetSteps, text: $vm.targetSteps)
                            TFPrimaryButton(L10n.Settings.syncPersonal, systemImage: "person.crop.circle.badge.checkmark") {
                                vm.syncPersonalInfo()
                            }
                        }
                    }

                    TFCard(title: L10n.Settings.devicePrefs, subtitle: L10n.Settings.devicePrefsSub) {
                        Toggle(isOn: $vm.useMetric) {
                            Label(L10n.Settings.metric, systemImage: "ruler")
                        }
                        .tint(AppTheme.accent)
                        .foregroundStyle(.white)
                        Toggle(isOn: $vm.use24h) {
                            Label(L10n.Settings.time24, systemImage: "clock")
                        }
                        .tint(AppTheme.accent)
                        .foregroundStyle(.white)
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(isOn: $vm.autoHR) {
                                Label(L10n.Settings.autoHr, systemImage: "heart.text.square")
                            }
                            .tint(AppTheme.accent)
                            .foregroundStyle(.white)
                            Text(L10n.Settings.autoHrHint)
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.4))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Toggle(isOn: $vm.autoTemperature) {
                            Label(L10n.Settings.autoTemp, systemImage: "thermometer")
                        }
                        .tint(AppTheme.accent)
                        .foregroundStyle(.white)
                        TFPrimaryButton(L10n.Settings.applyToggles, systemImage: "arrow.triangle.2.circlepath") {
                            vm.applyDeviceTogglesToWatch()
                        }
                        .padding(.top, 8)
                    }

                    TFCard(title: L10n.Settings.timeCard, subtitle: L10n.Settings.timeCardSub) {
                        TFSecondaryButton(L10n.Settings.syncTimeBand) {
                            vm.healthService.syncTime()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(L10n.Settings.title)
            .navigationBarTitleDisplayMode(.large)
            .tfNavigationChrome()
        }
    }

    private func field(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.45))
            TextField(title, text: text)
                .keyboardType(.numberPad)
                .padding(12)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.08))
                }
                .foregroundStyle(.white)
        }
    }
}
