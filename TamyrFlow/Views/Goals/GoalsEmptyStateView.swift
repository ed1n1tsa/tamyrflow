import SwiftUI

struct GoalsEmptyStateView: View {
    var onCreate: () -> Void

    private let previewCategories: [GoalCategory] = [.steps, .activity, .sleep, .water]

    var body: some View {
        VStack(spacing: 0) {
            Text(L10n.Goals.screenTitle)
                .font(AppFont.interBold(28))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, ProfileTheme.contentInset)
                .padding(.top, 12)

            Spacer(minLength: 12)

            Image("GoalIconTarget")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 260, maxHeight: 220)
                .accessibilityHidden(true)

            Text(L10n.Goals.emptyHeadline)
                .font(AppFont.interBold(22))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 18)
                .padding(.horizontal, 28)

            Text(L10n.Goals.emptySub)
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
                .padding(.horizontal, 36)

            HStack(spacing: 14) {
                ForEach(previewCategories) { cat in
                    Image(cat.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 56, height: 56)
                }
            }
            .padding(.top, 28)

            Spacer(minLength: 16)

            Button(action: onCreate) {
                Text(L10n.Goals.createCTA)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        Capsule(style: .continuous)
                            .fill(ProfileTheme.accent)
                    )
                    .shadow(color: ProfileTheme.accent.opacity(0.35), radius: 12, y: 3)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, ProfileTheme.contentInset)
            .padding(.bottom, 20)
        }
    }
}
