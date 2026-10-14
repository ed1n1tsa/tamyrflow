import SwiftUI

struct ActivityEmptyStateView: View {
    var onAdd: () -> Void
    var onOpenGoals: () -> Void
    var hasGoals: Bool
    var goals: [Goal]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 22) {
                ZStack {
                    Image("ActEmptyHero")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 220, maxHeight: 200)

                    // Orbiting metric chips (from Goals icons).
                    Group {
                        orbitIcon("GoalIconActivity", x: -88, y: -40)
                        orbitIcon("GoalIconWater", x: 88, y: -36)
                        orbitIcon("GoalIconWeight", x: -80, y: 56)
                        orbitIcon("GoalIconSleep", x: 82, y: 52)
                    }
                }
                .padding(.top, 12)

                Text(L10n.Activity.emptyTitle)
                    .font(AppFont.interBold(22))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(L10n.Activity.emptySub)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 28)

                Button(action: onAdd) {
                    HStack(spacing: 10) {
                        Image(systemName: "figure.walk")
                        Text(L10n.Activity.addFirst)
                    }
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Capsule().fill(ProfileTheme.accent))
                    .shadow(color: ProfileTheme.accent.opacity(0.35), radius: 12, y: 3)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, ProfileTheme.contentInset)

                trackableCard
                goalsBlock
            }
            .padding(.bottom, 28)
        }
    }

    private func orbitIcon(_ name: String, x: CGFloat, y: CGFloat) -> some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: 44, height: 44)
            .offset(x: x, y: y)
    }

    private var trackableCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                Image(systemName: "sparkles")
                    .foregroundStyle(ProfileTheme.accent)
                Text(L10n.Activity.trackableTitle)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
            }
            Text(L10n.Activity.trackableSub)
                .font(AppFont.interBold(12))
                .foregroundStyle(ProfileTheme.muted)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                trackCell(asset: "ActCatWorkouts", title: L10n.Activity.trackWorkouts, sub: L10n.Activity.trackWorkoutsSub)
                trackCell(asset: "GoalIconActivity", title: L10n.Activity.trackCalories, sub: L10n.Activity.trackCaloriesSub)
                trackCell(asset: "GoalIconSleep", title: L10n.Activity.trackSleep, sub: L10n.Activity.trackSleepSub)
                trackCell(asset: "GoalIconWater", title: L10n.Activity.trackWater, sub: L10n.Activity.trackWaterSub)
            }
        }
        .padding(16)
        .profileCard()
        .padding(.horizontal, ProfileTheme.contentInset)
    }

    private func trackCell(asset: String, title: String, sub: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(asset)
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
            Text(title)
                .font(AppFont.interBold(14))
                .foregroundStyle(.white)
            Text(sub)
                .font(AppFont.interBold(11))
                .foregroundStyle(ProfileTheme.muted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }

    @ViewBuilder
    private var goalsBlock: some View {
        if hasGoals {
            VStack(alignment: .leading, spacing: 12) {
                Text(L10n.Activity.activeGoalsTitle)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                ForEach(goals.prefix(3)) { goal in
                    HStack(spacing: 12) {
                        Image(goal.category.assetName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                        Text(L10n.Goals.title(for: goal.category))
                            .font(AppFont.interBold(14))
                            .foregroundStyle(.white)
                        Spacer()
                        Text("\(Int(goal.targetValue.rounded())) \(L10n.Goals.unitHint(for: goal.category))")
                            .font(AppFont.interBold(12))
                            .foregroundStyle(ProfileTheme.muted)
                    }
                }
                Button(action: onOpenGoals) {
                    Text(L10n.Activity.openGoals)
                        .font(AppFont.interBold(14))
                        .foregroundStyle(ProfileTheme.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .profileCard()
            .padding(.horizontal, ProfileTheme.contentInset)
        } else {
            Button(action: onOpenGoals) {
                HStack(spacing: 14) {
                    Image("GoalIconTarget")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                    VStack(alignment: .leading, spacing: 6) {
                        Text(L10n.Activity.setGoalsTitle)
                            .font(AppFont.interBold(15))
                            .foregroundStyle(.white)
                        Text(L10n.Activity.setGoalsSub)
                            .font(AppFont.interBold(12))
                            .foregroundStyle(ProfileTheme.muted)
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(ProfileTheme.muted)
                }
                .padding(16)
                .profileCard()
            }
            .buttonStyle(.plain)
            .padding(.horizontal, ProfileTheme.contentInset)
        }
    }
}
