import SwiftUI

struct GoalsListView: View {
    @ObservedObject var service: GoalsService
    var onCreate: () -> Void
    var onEdit: (Goal) -> Void
    var onHistory: () -> Void

    var body: some View {
        List {
            Section {
                HStack {
                    Text(L10n.Goals.screenTitle)
                        .font(AppFont.interBold(28))
                        .foregroundStyle(.white)
                    Spacer()
                    Button(action: onCreate) {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(Circle().fill(ProfileTheme.accent))
                    }
                    .buttonStyle(.plain)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 8, leading: ProfileTheme.contentInset, bottom: 8, trailing: ProfileTheme.contentInset))
                .listRowSeparator(.hidden)

                summaryCard
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 6, leading: ProfileTheme.contentInset, bottom: 6, trailing: ProfileTheme.contentInset))
                    .listRowSeparator(.hidden)
            }

            Section {
                ForEach(service.goals) { goal in
                    goalRow(goal)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 6, leading: ProfileTheme.contentInset, bottom: 6, trailing: ProfileTheme.contentInset))
                        .listRowSeparator(.hidden)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                Task { try? await service.delete(goal) }
                            } label: {
                                Label(L10n.Goals.delete, systemImage: "trash")
                            }
                            Button {
                                onEdit(goal)
                            } label: {
                                Label(L10n.Goals.edit, systemImage: "pencil")
                            }
                            .tint(ProfileTheme.accent)
                        }
                }
            }

            Section {
                Button(action: onHistory) {
                    HStack {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16, weight: .semibold))
                        Text(L10n.Goals.historyTitle)
                            .font(AppFont.interBold(15))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(ProfileTheme.muted)
                    }
                    .foregroundStyle(.white)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                            .fill(ProfileTheme.cardFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                                    .strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(.plain)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 10, leading: ProfileTheme.contentInset, bottom: 28, trailing: ProfileTheme.contentInset))
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .background(Color.clear)
    }

    private var summaryCard: some View {
        let done = service.completedCount
        let total = max(service.goals.count, 1)
        let ratio = CGFloat(done) / CGFloat(total)

        return VStack(alignment: .leading, spacing: 12) {
            Text(String(format: L10n.Goals.summaryFormat, done, service.goals.count))
                .font(AppFont.interBold(16))
                .foregroundStyle(.white)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.12))
                    Capsule()
                        .fill(ProfileTheme.accent)
                        .frame(width: geo.size.width * ratio)
                }
            }
            .frame(height: 8)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                .fill(ProfileTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                        .strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
                )
        )
    }

    private func goalRow(_ goal: Goal) -> some View {
        let current = service.currentValue(for: goal)
        let ratio = service.progressRatio(for: goal)
        let canQuickAdd = goal.category.quickAddAmount != nil

        return HStack(spacing: 14) {
            Image(goal.category.assetName)
                .resizable()
                .scaledToFit()
                .frame(width: 52, height: 52)

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.Goals.title(for: goal.category))
                    .font(AppFont.interBold(15))
                    .foregroundStyle(.white)
                Text(L10n.Goals.progressLabel(current: current, target: goal.targetValue, category: goal.category))
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.muted)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.1))
                        Capsule()
                            .fill(ProfileTheme.accent)
                            .frame(width: geo.size.width * CGFloat(ratio))
                    }
                }
                .frame(height: 7)
            }

            if canQuickAdd {
                Button {
                    Task { await service.quickAdd(to: goal) }
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(ProfileTheme.accent.opacity(0.9)))
                }
                .buttonStyle(.plain)
            } else {
                Text("\(Int((ratio * 100).rounded()))%")
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.accent)
                    .frame(width: 40, alignment: .trailing)
            }
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
}
