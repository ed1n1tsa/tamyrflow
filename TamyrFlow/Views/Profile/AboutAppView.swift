import SwiftUI

/// «О приложении» — template screen from Figma (contact only in links for now).
struct AboutAppView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    private var versionLabel: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.0"
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
                    VStack(alignment: .leading, spacing: 20) {
                        brandCard
                        missionCard
                        featuresCard
                        disclaimerCard
                        contactRow
                    }
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 18)
                    .padding(.bottom, 32)
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
        HStack(alignment: .top, spacing: 16) {
            // Own logo only — no frame / glow.
            Image("BrandLogoTF")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 10) {
                Text("Tamyr Flow")
                    .font(AppFont.interBold(22))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)

                Text(versionLabel)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.muted)

                Text(L10n.About.tagline)
                    .font(AppFont.interBold(14))
                    .foregroundStyle(Color.white.opacity(0.78))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "dumbbell.fill")
                .font(.system(size: 30, weight: .semibold))
                .foregroundStyle(ProfileTheme.accent)
                .frame(width: 36, height: 36)
                .padding(.top, 4)
        }
        .padding(20)
        .profileCard()
    }

    private var missionCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                Image(systemName: "target")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(ProfileTheme.accent)
                    .frame(width: 48, height: 48)
                    .background(Circle().fill(ProfileTheme.accent.opacity(0.18)))

                Text(L10n.About.missionTitle)
                    .font(AppFont.interBold(18))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Text(L10n.About.missionBody)
                .font(AppFont.interBold(14))
                .foregroundStyle(Color.white.opacity(0.72))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .profileCard()
    }

    private var featuresCard: some View {
        Grid(alignment: .topLeading, horizontalSpacing: 18, verticalSpacing: 22) {
            GridRow {
                featureCell(
                    systemImage: "chart.bar.fill",
                    title: L10n.About.featureTrackTitle,
                    body: L10n.About.featureTrackBody
                )
                featureCell(
                    systemImage: "trophy.fill",
                    title: L10n.About.featureAchieveTitle,
                    body: L10n.About.featureAchieveBody
                )
            }
            GridRow {
                featureCell(
                    systemImage: "calendar",
                    title: L10n.About.featureHabitsTitle,
                    body: L10n.About.featureHabitsBody
                )
                featureCell(
                    systemImage: "heart.fill",
                    title: L10n.About.featureMotivateTitle,
                    body: L10n.About.featureMotivateBody
                )
            }
        }
        .padding(20)
        .profileCard()
    }

    private func featureCell(systemImage: String, title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(ProfileTheme.accent)
                .frame(width: 28, height: 28, alignment: .leading)

            Text(title)
                .font(AppFont.interBold(15))
                .foregroundStyle(.white)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Text(body)
                .font(AppFont.interBold(12))
                .foregroundStyle(Color.white.opacity(0.68))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
        .gridCellColumns(1)
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(ProfileTheme.accent)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(ProfileTheme.accent.opacity(0.18)))
                Text(L10n.About.disclaimerTitle)
                    .font(AppFont.interBold(17))
                    .foregroundStyle(.white)
            }

            Text(L10n.About.disclaimerBody)
                .font(AppFont.interBold(14))
                .foregroundStyle(Color.white.opacity(0.72))
                .lineSpacing(6)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(ProfileTheme.accent)
                    .padding(.top, 1)
                Text(L10n.About.disclaimerWarn)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(Color.white.opacity(0.78))
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(ProfileTheme.accent.opacity(0.12))
            )
        }
        .padding(20)
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
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ProfileTheme.accent)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(ProfileTheme.accent.opacity(0.16)))

                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.About.contactTitle)
                        .font(AppFont.interBold(15))
                        .foregroundStyle(.white)
                    Text(L10n.About.contactSub)
                        .font(AppFont.interBold(13))
                        .foregroundStyle(Color.white.opacity(0.68))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(ProfileTheme.muted)
            }
            .padding(18)
            .profileCard()
        }
        .buttonStyle(.plain)
    }
}
