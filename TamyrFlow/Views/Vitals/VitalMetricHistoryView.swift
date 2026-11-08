import SwiftUI

struct VitalMetricHistoryView: View {
    @ObservedObject var service: VitalMetricService
    @Environment(\.dismiss) private var dismiss
    @State private var rows: [VitalMeasurement] = []
    @State private var isLoading = false

    private var accent: Color { service.kind.accent }
    private var iconName: String { service.kind.iconSystemName }

    var body: some View {
        ZStack {
            GoalsBackgroundView()
            VStack(spacing: 0) {
                HStack {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(.plain)
                    Spacer()
                    Text(L10n.Vital.historyTitle)
                        .font(AppFont.interBold(17))
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, ProfileTheme.contentInset)
                .padding(.top, 6)

                if isLoading && rows.isEmpty {
                    Spacer()
                    ProgressView().tint(accent)
                    Spacer()
                } else if rows.isEmpty {
                    Spacer()
                    Text(L10n.Pulse.noData)
                        .font(AppFont.interBold(15))
                        .foregroundStyle(ProfileTheme.muted)
                    Text(L10n.Pulse.historyEmptySub)
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .padding(.top, 8)
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(rows) { item in
                                HStack(spacing: 12) {
                                    Image(systemName: iconName)
                                        .foregroundStyle(accent)
                                        .frame(width: 36, height: 36)
                                        .background(Circle().fill(accent.opacity(0.16)))
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(VitalMetricFormatters.displayValue(item, kind: service.kind))
                                            .font(AppFont.interBold(15))
                                            .foregroundStyle(.white)
                                        Text("\(PulseFormatters.shortDateTime(item.recordedAt)) · \(PulseFormatters.sourceTitle(item.source))")
                                            .font(AppFont.interBold(11))
                                            .foregroundStyle(ProfileTheme.muted)
                                    }
                                    Spacer(minLength: 0)
                                }
                                .padding(14)
                                .background(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .fill(ProfileTheme.cardFill)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                                .strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
                                        )
                                )
                            }
                        }
                        .padding(.horizontal, ProfileTheme.contentInset)
                        .padding(.top, 12)
                        .padding(.bottom, 28)
                    }
                }
            }
        }
        .navigationBarHidden(true)
        .task {
            isLoading = true
            rows = await service.loadHistory(limit: 100, offset: 0)
            isLoading = false
        }
    }
}
