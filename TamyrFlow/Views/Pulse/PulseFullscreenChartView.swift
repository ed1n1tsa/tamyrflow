import SwiftUI

struct PulseFullscreenChartView: View {
    @ObservedObject var service: PulseService
    @Environment(\.dismiss) private var dismiss
    @State private var selected: PulseChartPoint?

    var body: some View {
        ZStack {
            GoalsBackgroundView()

            VStack(spacing: 0) {
                HStack {
                    Text(L10n.Pulse.dynamicsTitle)
                        .font(AppFont.interBold(18))
                        .foregroundStyle(.white)
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(ProfileTheme.cardFill))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, ProfileTheme.contentInset)
                .padding(.top, 12)

                periodPills
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 14)

                PulseChartView(
                    points: service.chartPoints,
                    period: service.period,
                    selected: $selected,
                    emptyMessage: L10n.Pulse.noData,
                    emptySub: L10n.Pulse.chartEmptySub
                )
                .padding(ProfileTheme.contentInset)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(ProfileTheme.cardFill)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
                        )
                )
                .padding(.horizontal, ProfileTheme.contentInset)
                .padding(.top, 16)

                Spacer()
            }
        }
    }

    private var periodPills: some View {
        HStack(spacing: 8) {
            ForEach(PulsePeriod.allCases) { period in
                let selected = service.period == period
                Button {
                    Task { await service.setPeriod(period) }
                } label: {
                    Text(L10n.Pulse.periodLabel(period))
                        .font(AppFont.interBold(14))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(ProfileTheme.accent)
                                    .shadow(color: ProfileTheme.accent.opacity(0.4), radius: 8, y: 2)
                            } else {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(ProfileTheme.cardFill)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
                                    )
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }
}
