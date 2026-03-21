import SwiftUI
import VeepooBleSDK

struct ECGPage: View {
    @EnvironmentObject private var vm: BluetoothViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if vm.healthService.supportsECG {
                        ECGWaveformView(
                            samples: vm.healthService.ecgWaveformMv,
                            isLive: vm.healthService.operation == .ecgTest,
                            liveHeartRate: vm.healthService.ecgLiveHeartRate
                        )
                    }

                    TFCard(
                        title: vm.healthService.supportsECG ? L10n.ECG.supported : L10n.ECG.notAvail,
                        subtitle: vm.healthService.supportsECG ? L10n.ECG.supportedSub : L10n.ECG.notAvailSub
                    ) {
                        HStack(spacing: 16) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L10n.ECG.progress)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.45))
                                Text("\(vm.healthService.ecg?.progress ?? 0)%")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(AppTheme.accent)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(L10n.ECG.samples)
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.45))
                                Text("\(vm.healthService.ecg?.sampleCount ?? 0)")
                                    .font(.title2.weight(.bold))
                                    .foregroundStyle(AppTheme.accentSecondary)
                            }
                        }
                    }

                    TFCard(title: L10n.ECG.curve, subtitle: ecgSubtitle) {
                        LiveMetricChart(
                            title: L10n.ECG.progressPct,
                            data: vm.healthService.ecgProgressHistory,
                            unit: "%",
                            color: Color.mint,
                            yDomain: 0...100
                        )
                    }

                    if vm.healthService.supportsECG {
                        TFCard(title: L10n.ECG.controls, subtitle: L10n.ECG.controlsSub) {
                            HStack(spacing: 12) {
                                TFPrimaryButton(L10n.ECG.start, systemImage: "waveform.path.ecg") {
                                    vm.healthService.startECGTest()
                                }
                                TFSecondaryButton(L10n.btnStop) {
                                    vm.healthService.stopECGTest()
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(L10n.ECG.title)
            .navigationBarTitleDisplayMode(.large)
            .tfNavigationChrome()
        }
    }

    private var ecgSubtitle: String {
        let raw = vm.healthService.ecg?.state.rawValue ?? -1
        switch raw {
        case 0: return L10n.State.preparing
        case 1: return L10n.State.recording
        case 2: return L10n.State.leadOff
        case 3: return L10n.State.busy
        case 4: return L10n.State.stopped
        case 5: return L10n.State.failed
        case 6: return L10n.State.complete
        case 7: return L10n.State.noFunc
        default: return L10n.State.idle
        }
    }
}
