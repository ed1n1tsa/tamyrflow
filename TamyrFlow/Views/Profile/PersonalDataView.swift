import Auth
import SwiftUI

/// Read-only «Личные данные» screen (Figma).
struct PersonalDataView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss

    private var profile: UserProfile? { auth.profile }

    var body: some View {
        ZStack {
            ProfileSetupBackground()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        titleBlock
                        summaryCard
                        fieldCard(
                            symbolText: genderSymbol,
                            label: L10n.Profile.gender,
                            value: genderLabel
                        )
                        fieldCard(
                            systemImage: "calendar",
                            label: L10n.Profile.age,
                            value: ageLabel
                        )
                        fieldCard(
                            systemImage: "ruler",
                            label: L10n.Profile.height,
                            value: heightLabel
                        )
                        fieldCard(
                            systemImage: "scalemass.fill",
                            label: L10n.Profile.weight,
                            value: weightLabel
                        )
                        fieldCard(
                            systemImage: "envelope.fill",
                            label: L10n.PersonalData.emailLabel,
                            value: emailLabel
                        )
                    }
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationBarHidden(true)
        .id(language.code)
        .task {
            await auth.refreshProfile()
        }
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

            HStack(spacing: 8) {
                BrandLogoMark()
                Text("TAMYR FLOW")
                    .font(AppFont.interBold(14))
                    .tracking(1)
                    .foregroundStyle(.white)
            }

            Spacer()

            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(8)
                Circle()
                    .fill(AppTheme.danger)
                    .frame(width: 8, height: 8)
                    .offset(x: -4, y: 4)
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.PersonalData.title)
                .font(AppFont.interBold(28))
                .foregroundStyle(.white)
            Text(L10n.PersonalData.subtitle)
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 14) {
            ProfileAvatarView(urlString: profile?.avatarUrl, size: 64)

            VStack(alignment: .leading, spacing: 5) {
                Text(profile?.displayName ?? "—")
                    .font(AppFont.interBold(20))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Text(emailLabel)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.muted)
                    .lineLimit(1)
                    .truncationMode(.middle)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .personalCard()
    }

    private func fieldCard(systemImage: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(ProfileTheme.accent)
                .frame(width: 44, height: 44)
                .background(Circle().fill(ProfileTheme.accent.opacity(0.16)))

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.muted)
                Text(value)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .personalCard()
    }

    private func fieldCard(symbolText: String, label: String, value: String) -> some View {
        HStack(spacing: 14) {
            Text(symbolText)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(ProfileTheme.accent)
                .frame(width: 44, height: 44)
                .background(Circle().fill(ProfileTheme.accent.opacity(0.16)))

            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.muted)
                Text(value)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .personalCard()
    }

    // MARK: - Labels

    private var emailLabel: String {
        profile?.email ?? auth.session?.user.email ?? "—"
    }

    private var genderSymbol: String {
        switch profile?.gender {
        case .male: return "♂"
        case .female: return "♀"
        case .unspecified, .none: return "⊘"
        }
    }

    private var genderLabel: String {
        switch profile?.gender {
        case .male: return L10n.ProfileSetup.genderMale
        case .female: return L10n.ProfileSetup.genderFemale
        case .unspecified: return L10n.Profile.genderUnspecifiedShort
        case .none: return "—"
        }
    }

    private var ageLabel: String {
        guard let age = profile?.age else { return "—" }
        return String(format: L10n.ProfileSetup.ageYearsFormat, age)
    }

    private var heightLabel: String {
        guard let h = profile?.heightCm else { return "—" }
        return "\(h) \(L10n.ProfileSetup.cmUnit)"
    }

    private var weightLabel: String {
        guard let w = profile?.weightKg else { return "—" }
        if w.rounded() == w {
            return "\(Int(w)) \(L10n.ProfileSetup.kgUnit)"
        }
        return String(format: "%.1f %@", w, L10n.ProfileSetup.kgUnit)
    }
}

private extension View {
    func personalCard() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                    .fill(ProfileTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                            .stroke(ProfileTheme.cardBorder, lineWidth: 1)
                    )
            )
    }
}
