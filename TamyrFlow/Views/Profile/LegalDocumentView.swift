import SwiftUI

enum LegalDocumentKind {
    case terms
    case privacyPolicy
    case privacyControls

    var title: String {
        switch self {
        case .terms: return L10n.Profile.menuTerms
        case .privacyPolicy: return L10n.Profile.menuPolicy
        case .privacyControls: return L10n.Profile.menuPrivacy
        }
    }

    var paragraphs: [String] {
        switch self {
        case .terms:
            return [
                L10n.Legal.terms1,
                L10n.Legal.terms2,
                L10n.Legal.terms3,
                L10n.Legal.terms4
            ]
        case .privacyPolicy:
            return [
                L10n.Legal.policy1,
                L10n.Legal.policy2,
                L10n.Legal.policy3,
                L10n.Legal.policy4
            ]
        case .privacyControls:
            return [
                L10n.Legal.controls1,
                L10n.Legal.controls2,
                L10n.Legal.controls3
            ]
        }
    }
}

struct LegalDocumentView: View {
    let kind: LegalDocumentKind
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ProfileSetupBackground()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(kind.title)
                            .font(AppFont.interBold(28))
                            .foregroundStyle(.white)

                        ForEach(Array(kind.paragraphs.enumerated()), id: \.offset) { _, text in
                            Text(text)
                                .font(AppFont.interBold(14))
                                .foregroundStyle(Color.white.opacity(0.78))
                                .lineSpacing(5)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .profileCard()
                        }
                    }
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 14)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .id(language.code)
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
            Text(kind.title)
                .font(AppFont.interBold(17))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
    }
}

/// Honest “not in first release” page instead of a stub alert.
struct DeferredFeatureView: View {
    let title: String
    let bodyText: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            ProfileSetupBackground()
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
                    Text(title)
                        .font(AppFont.interBold(17))
                        .foregroundStyle(.white)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, ProfileTheme.contentInset)
                .padding(.top, 6)

                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(ProfileTheme.accent)
                    Text(title)
                        .font(AppFont.interBold(22))
                        .foregroundStyle(.white)
                    Text(bodyText)
                        .font(AppFont.interBold(14))
                        .foregroundStyle(ProfileTheme.muted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                    Spacer()
                }
            }
        }
        .navigationBarHidden(true)
    }
}
