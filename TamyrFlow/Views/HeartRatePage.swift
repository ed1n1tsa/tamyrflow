import SwiftUI
import VeepooBleSDK

struct HeartRatePage: View {
    @EnvironmentObject private var vm: BluetoothViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TFMetricBadge(
                        value: "\(vm.healthService.heartRate?.value ?? 0)",
                        unit: "bpm",
                        label: L10n.Heart.currentLabel,
                        tint: Color.pink
                    )
                    .padding(.vertical, 8)
                    .background {
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(AppTheme.cardBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: 20, style: .continuous)
                                    .stroke(AppTheme.cardBorder, lineWidth: 1)
                            }
                    }

                    TFCard(title: L10n.Heart.liveChart, subtitle: heartSubtitle) {
                        LiveMetricChart(
                            title: L10n.Heart.bpmTime,
                            data: vm.healthService.heartRateHistory,
                            unit: "bpm",
                            color: Color.pink,
                            yDomain: heartYDomain
                        )
                    }

                    TFCard(title: L10n.Heart.manual, subtitle: L10n.Heart.manualSub) {
                        HStack(spacing: 12) {
                            TFPrimaryButton(L10n.btnStart, systemImage: "play.fill") {
                                vm.healthService.startHeartTest()
                            }
                            TFSecondaryButton(L10n.btnStop) {
                                vm.healthService.stopHeartTest()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(L10n.Heart.title)
            .navigationBarTitleDisplayMode(.large)
            .tfNavigationChrome()
        }
    }

    private var heartSubtitle: String {
        let raw = vm.healthService.heartRate?.state.rawValue ?? -1
        switch raw {
        case 0: return L10n.State.starting
        case 1: return L10n.State.measuring
        case 2: return L10n.State.notWorn
        case 3: return L10n.State.deviceBusy
        case 4: return L10n.State.finished
        default: return L10n.State.idle
        }
    }

    private var heartYDomain: ClosedRange<Double>? {
        let pts = vm.healthService.heartRateHistory.map(\.value)
        guard let maxV = pts.max(), maxV > 0 else { return 40...200 }
        let minV = max(40, (pts.min() ?? 50) - 10)
        let hi = max(120, maxV + 15)
        return minV...hi
    }
}
