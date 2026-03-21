import SwiftUI

struct TemperaturePage: View {
    @EnvironmentObject private var vm: BluetoothViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if vm.healthService.supportsTemperature {
                        HStack(spacing: 12) {
                            TFMetricBadge(
                                value: String(format: "%.1f", vm.healthService.temperature?.bodyTemperature ?? 0.0),
                                unit: L10n.Temp.celsius,
                                label: L10n.Temp.body,
                                tint: AppTheme.accent
                            )
                            TFMetricBadge(
                                value: String(format: "%.1f", vm.healthService.temperature?.skinTemperature ?? 0.0),
                                unit: L10n.Temp.celsius,
                                label: L10n.Temp.skin,
                                tint: AppTheme.accentSecondary
                            )
                        }
                        .padding(.vertical, 8)
                        .background {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(AppTheme.cardBackground)
                                .overlay {
                                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                                }
                        }

                        TFCard(
                            title: L10n.Temp.trend,
                            subtitle: L10n.Temp.trendSub(progress: vm.healthService.temperature?.progress ?? 0)
                        ) {
                            LiveMetricChart(
                                title: L10n.Temp.celsius,
                                data: vm.healthService.bodyTemperatureHistory,
                                unit: L10n.Temp.celsius,
                                color: Color.orange
                            )
                        }

                        TFCard(title: L10n.Temp.manual, subtitle: L10n.Temp.manualSub) {
                            HStack(spacing: 12) {
                                TFPrimaryButton(L10n.btnStart, systemImage: "play.fill") {
                                    vm.healthService.startTemperatureTest()
                                }
                                TFSecondaryButton(L10n.btnStop) {
                                    vm.healthService.stopTemperatureTest()
                                }
                            }
                        }
                    } else {
                        TFCard(title: L10n.Temp.notSupported, subtitle: L10n.Temp.notSupportedSub) {
                            Image(systemName: "thermometer.slash")
                                .font(.largeTitle)
                                .foregroundStyle(.white.opacity(0.25))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 20)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(L10n.Temp.title)
            .navigationBarTitleDisplayMode(.large)
            .tfNavigationChrome()
        }
    }
}
