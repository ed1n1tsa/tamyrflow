import SwiftUI
import VeepooBleSDK

struct MicroTestPage: View {
    @EnvironmentObject private var vm: BluetoothViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TFCard(
                        title: L10n.Micro.check,
                        subtitle: vm.healthService.supportsMicroTest ? L10n.Micro.checkOkSub : L10n.Micro.checkNoSub
                    ) {
                        TFMetricBadge(
                            value: "\(vm.healthService.microTest?.progress ?? 0)",
                            unit: "%",
                            label: L10n.Micro.progressLabel,
                            tint: AppTheme.accent
                        )
                    }

                    TFCard(title: L10n.Micro.chart, subtitle: L10n.Micro.chartSub) {
                        LiveMetricChart(
                            title: L10n.Micro.completion,
                            data: vm.healthService.microProgressHistory,
                            unit: "%",
                            color: Color.cyan,
                            yDomain: 0...100
                        )
                    }

                    if vm.healthService.supportsMicroTest {
                        TFCard(title: L10n.Micro.run, subtitle: L10n.Micro.runSub) {
                            HStack(spacing: 12) {
                                TFPrimaryButton(L10n.btnStart, systemImage: "play.fill") {
                                    vm.healthService.startMicroTest()
                                }
                                TFSecondaryButton(L10n.btnStop) {
                                    vm.healthService.stopMicroTest()
                                }
                            }
                        }
                    }

                    let result = vm.healthService.microTest?.model
                    TFCard(
                        title: L10n.Micro.last,
                        subtitle: result == nil ? L10n.Micro.lastSubNone : L10n.Micro.lastSubOk
                    ) {
                        resultGrid(result: result)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(L10n.Micro.title)
            .navigationBarTitleDisplayMode(.large)
            .tfNavigationChrome()
        }
    }

    @ViewBuilder
    private func resultGrid(result: VPMicroTestModel?) -> some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            metricCell("HR", "\(result?.heartRate ?? 0)", "bpm")
            metricCell("SpO₂", "\(result?.bloodOxygen ?? 0)", "%")
            metricCell(L10n.Micro.metricStress, "\(result?.pressure ?? 0)", "")
            metricCell(L10n.Micro.metricTemp, String(format: "%.1f", result.map { Double($0.bodyTemperature) } ?? 0.0), L10n.Temp.celsius)
            metricCell("SYS", "\(result?.systolicBloodPressure ?? 0)", L10n.Micro.unitMmHg)
            metricCell("DIA", "\(result?.diastolicBloodPressure ?? 0)", L10n.Micro.unitMmHg)
            metricCell("HRV", "\(result?.hrv ?? 0)", "ms")
        }
    }

    private func metricCell(_ title: String, _ value: String, _ unit: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.45))
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.06))
        }
    }
}
