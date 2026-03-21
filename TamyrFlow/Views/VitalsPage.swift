import SwiftUI

struct VitalsPage: View {
    @EnvironmentObject private var vm: BluetoothViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    TFCard(title: L10n.Vitals.bpCard, subtitle: L10n.Vitals.bpSub) {
                        LabeledContent(L10n.Vitals.lastReading) {
                            Text(bpLine)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .foregroundStyle(.white.opacity(0.55))

                        HStack(spacing: 12) {
                            TFPrimaryButton(L10n.btnStart, systemImage: "play.fill") {
                                vm.healthService.startBloodPressureTest()
                            }
                            .disabled(!vm.healthService.isConnected || !vm.healthService.canRunManualTests || !vm.bleService.isSDKConfigured)

                            TFSecondaryButton(L10n.btnStop) {
                                vm.healthService.stopBloodPressureTest()
                            }
                        }
                    }

                    TFCard(title: L10n.Vitals.glucoseCard, subtitle: L10n.Vitals.glucoseSub) {
                        LabeledContent(L10n.Vitals.lastReading) {
                            Text(glucoseLine)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(.white)
                        }
                        .foregroundStyle(.white.opacity(0.55))

                        HStack(spacing: 12) {
                            TFPrimaryButton(L10n.btnStart, systemImage: "play.fill") {
                                vm.healthService.startBloodGlucoseTest()
                            }
                            .disabled(!vm.healthService.isConnected || !vm.healthService.canRunManualTests || !vm.bleService.isSDKConfigured)

                            TFSecondaryButton(L10n.btnStop) {
                                vm.healthService.stopBloodGlucoseTest()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(L10n.Vitals.title)
            .navigationBarTitleDisplayMode(.large)
            .tfNavigationChrome()
        }
    }

    private var bpLine: String {
        guard let bp = vm.healthService.bloodPressure else { return "—" }
        if bp.systolic > 0 || bp.diastolic > 0 {
            return "\(bp.systolic)/\(bp.diastolic) mmHg"
        }
        return "—"
    }

    private var glucoseLine: String {
        guard let g = vm.healthService.bloodGlucose, g.valueRaw > 0 else { return "—" }
        return String(format: "%.2f %@", g.mmol, L10n.Vitals.mmol)
    }
}
