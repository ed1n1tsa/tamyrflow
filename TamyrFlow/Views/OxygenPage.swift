import SwiftUI
import VeepooBleSDK

struct OxygenPage: View {
    @EnvironmentObject private var vm: BluetoothViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TFMetricBadge(
                        value: "\(vm.healthService.oxygen?.value ?? 0)",
                        unit: "%",
                        label: L10n.Dashboard.spo2,
                        tint: AppTheme.accentSecondary
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

                    TFCard(title: L10n.Oxygen.liveChart, subtitle: oxygenSubtitle) {
                        LiveMetricChart(
                            title: L10n.Oxygen.o2Title,
                            data: vm.healthService.oxygenHistory,
                            unit: "%",
                            color: AppTheme.accentSecondary,
                            yDomain: 85...100
                        )
                    }

                    TFCard(title: L10n.Oxygen.manual, subtitle: L10n.Oxygen.manualSub) {
                        HStack(spacing: 12) {
                            TFPrimaryButton(L10n.btnStart, systemImage: "play.fill") {
                                vm.healthService.startOxygenTest()
                            }
                            TFSecondaryButton(L10n.btnStop) {
                                vm.healthService.stopOxygenTest()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(L10n.Oxygen.title)
            .navigationBarTitleDisplayMode(.large)
            .tfNavigationChrome()
        }
    }

    private var oxygenSubtitle: String {
        let raw = vm.healthService.oxygen?.state.rawValue ?? -1
        switch raw {
        case 0: return L10n.State.starting
        case 1: return L10n.State.measuring
        case 2: return L10n.State.notWorn
        case 3: return L10n.State.busy
        case 4: return L10n.State.done
        case 5: return L10n.State.unsupported
        case 6: return L10n.State.calibrating
        case 7: return L10n.State.calibDone
        case 8: return L10n.State.invalid
        default: return L10n.State.idle
        }
    }
}
