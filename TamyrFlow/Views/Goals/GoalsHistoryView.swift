import SwiftUI

/// Past goal_progress periods for the signed-in user.
struct GoalsHistoryView: View {
    @ObservedObject var service: GoalsService
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let _ = language.revision
        ZStack {
            GoalsBackgroundView()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 6)

                Group {
                    if service.isLoadingHistory && service.historyEntries.isEmpty {
                        Spacer()
                        ProgressView()
                            .tint(.white)
                        Spacer()
                    } else if service.historyEntries.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 36, weight: .semibold))
                                .foregroundStyle(ProfileTheme.accent)
                            Text(L10n.Goals.historyEmpty)
                                .font(AppFont.interBold(14))
                                .foregroundStyle(ProfileTheme.muted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 28)
                        }
                        Spacer()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 10) {
                                ForEach(service.historyEntries) { entry in
                                    historyRow(entry)
                                }
                            }
                            .padding(.horizontal, ProfileTheme.contentInset)
                            .padding(.top, 14)
                            .padding(.bottom, 32)
                        }
                    }
                }
            }
        }
        .task { await service.loadHistory() }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            Spacer()
            Text(L10n.Goals.historyTitle)
                .font(AppFont.interBold(17))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
    }

    private func historyRow(_ entry: GoalHistoryEntry) -> some View {
        HStack(spacing: 14) {
            Image(entry.category.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Goals.title(for: entry.category))
                    .font(AppFont.interBold(15))
                    .foregroundStyle(.white)
                Text(entry.periodStart)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.muted)
                Text(
                    String(
                        format: L10n.Goals.historyTargetFormat,
                        formatValue(entry.currentValue, category: entry.category),
                        formatValue(entry.targetValue, category: entry.category)
                    )
                )
                .font(AppFont.interBold(12))
                .foregroundStyle(ProfileTheme.muted)

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                        Capsule()
                            .fill(ProfileTheme.accent)
                            .frame(width: geo.size.width * CGFloat(entry.ratio))
                    }
                }
                .frame(height: 6)
            }

            Text("\(Int((entry.ratio * 100).rounded()))%")
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.accent)
                .frame(width: 40, alignment: .trailing)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                .fill(ProfileTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                        .strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
                )
        )
    }

    private func formatValue(_ value: Double, category: GoalCategory) -> String {
        switch category {
        case .steps, .activity:
            return "\(Int(value.rounded()))"
        case .sleep, .water, .weight:
            if value.rounded() == value {
                return "\(Int(value))"
            }
            return String(format: "%.1f", value)
        }
    }
}
