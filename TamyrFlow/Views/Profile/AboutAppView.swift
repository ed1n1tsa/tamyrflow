import SwiftUI

/// «О приложении» — template screen from Figma (contact only in links for now).
struct AboutAppView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var versionLabel: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return String(format: L10n.About.versionFormat, short, build)
    }

    var body: some View {
        ZStack {
            ProfileSetupBackground()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        brandCard
                        missionCard
                        featuresCard
                        disclaimerCard
                        contactRow
                    }
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationBarHidden(true)
        .id(language.code)
    }

    // MARK: - Chrome

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

            Text(L10n.About.title)
                .font(AppFont.interBold(17))
                .foregroundStyle(.white)

            Spacer()

            Color.clear.frame(width: 36, height: 36)
        }
    }

    // MARK: - Cards

    private var brandCard: some View {
        HStack(alignment: .center, spacing: 14) {
            Image("BrandLogoTF")
                .resizable()
                .scaledToFit()
                .frame(width: 56, height: 56)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(red: 0.05, green: 0.18, blue: 0.42))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(ProfileTheme.accent.opacity(0.85), lineWidth: 1.5)
                        )
                        .shadow(color: ProfileTheme.accent.opacity(0.35), radius: 10, y: 0)
                )

            VStack(alignment: .leading, spacing: 6) {
                Text("TAMYR FLOW")
                    .font(AppFont.interBold(20))
                    .foregroundStyle(.white)
                Text(versionLabel)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.muted)
                Text(L10n.About.tagline)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.accentSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 4)

            Image(systemName: "dumbbell.fill")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [ProfileTheme.accent, ProfileTheme.accentSoft],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .shadow(color: ProfileTheme.accent.opacity(0.55), radius: 12, y: 0)
                .frame(width: 64, height: 64)
        }
        .padding(16)
        .profileCard()
    }

    private var missionCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "target")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(ProfileTheme.accent)
                .frame(width: 36, height: 36)
                .background(Circle().fill(ProfileTheme.accent.opacity(0.18)))

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.About.missionTitle)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                Text(L10n.About.missionBody)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .profileCard()
    }

    private var featuresCard: some View {
        LazyVGrid(
            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
            spacing: 16
        ) {
            featureCell(systemImage: "chart.bar.fill", title: L10n.About.featureTrackTitle, body: L10n.About.featureTrackBody)
            featureCell(systemImage: "trophy.fill", title: L10n.About.featureAchieveTitle, body: L10n.About.featureAchieveBody)
            featureCell(systemImage: "calendar", title: L10n.About.featureHabitsTitle, body: L10n.About.featureHabitsBody)
            featureCell(systemImage: "heart.fill", title: L10n.About.featureMotivateTitle, body: L10n.About.featureMotivateBody)
        }
        .padding(16)
        .profileCard()
    }

    private func featureCell(systemImage: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(ProfileTheme.accent)
            Text(title)
                .font(AppFont.interBold(14))
                .foregroundStyle(.white)
            Text(body)
                .font(AppFont.interBold(11))
                .foregroundStyle(ProfileTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(ProfileTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(ProfileTheme.accent.opacity(0.18)))
                Text(L10n.About.disclaimerTitle)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
            }

            Text(L10n.About.disclaimerBody)
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.muted)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ProfileTheme.accent)
                Text(L10n.About.disclaimerWarn)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.accentSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ProfileTheme.accent.opacity(0.12))
            )
        }
        .padding(16)
        .profileCard()
    }

    private var contactRow: some View {
        Button {
            if let url = URL(string: "mailto:\(L10n.About.contactEmail)") {
                openURL(url)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ProfileTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(ProfileTheme.accent.opacity(0.16)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.About.contactTitle)
                        .font(AppFont.interBold(15))
                        .foregroundStyle(.white)
                    Text(L10n.About.contactSub)
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ProfileTheme.muted)
            }
            .padding(14)
            .profileCard()
        }
        .buttonStyle(.plain)
    }
}
