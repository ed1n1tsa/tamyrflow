import SwiftUI

enum LegalDocumentKind: Identifiable {
    case terms
    case privacyPolicy
    case privacyControls

    var id: String {
        switch self {
        case .terms: return "terms"
        case .privacyPolicy: return "privacyPolicy"
        case .privacyControls: return "privacyControls"
        }
    }

    var title: String {
        switch self {
        case .terms: return L10n.Profile.menuTerms
        case .privacyPolicy: return L10n.Profile.menuPolicy
        case .privacyControls: return L10n.Profile.menuPrivacy
        }
    }

    var paragraphs: [String] {
        switch self {
        case .terms, .privacyPolicy:
            return []
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
        let _ = language.revision
        ZStack {
            ProfileSetupBackground()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 6)

                ScrollView(showsIndicators: true) {
                    Group {
                        switch kind {
                        case .privacyPolicy:
                            richLegalBody(
                                title: PrivacyPolicyDocument.documentTitle,
                                updated: PrivacyPolicyDocument.updatedLabel,
                                sections: PrivacyPolicyDocument.sections
                            )
                        case .terms:
                            richLegalBody(
                                title: TermsOfUseDocument.documentTitle,
                                updated: TermsOfUseDocument.updatedLabel,
                                sections: TermsOfUseDocument.sections
                            )
                        case .privacyControls:
                            simpleParagraphsBody
                        }
                    }
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                    .id("legal-\(kindTitleKey)-\(language.code.rawValue)-\(language.revision)")
                }
            }
        }
        .navigationBarHidden(true)
    }

    private var kindTitleKey: String {
        switch kind {
        case .terms: return "terms"
        case .privacyPolicy: return "privacy"
        case .privacyControls: return "controls"
        }
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

    private var simpleParagraphsBody: some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(kind.paragraphs.enumerated()), id: \.offset) { _, text in
                Text(text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(sectionChrome)
            }
        }
    }

    /// App Store–friendly: clear section separation, readable body, no wall of text.
    private func richLegalBody(
        title: String,
        updated: String,
        sections: [LegalRichDocument.Section]
    ) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(AppFont.interBold(24))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)

                Text(updated)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(ProfileTheme.muted)
            }
            .padding(.bottom, 4)

            ForEach(sections) { section in
                VStack(alignment: .leading, spacing: 10) {
                    Text(section.title)
                        .font(AppFont.interBold(17))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    Rectangle()
                        .fill(ProfileTheme.accent.opacity(0.55))
                        .frame(width: 36, height: 2)
                        .padding(.bottom, 2)

                    ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                        switch block {
                        case .paragraph(let text):
                            if isSubhead(text) {
                                Text(text)
                                    .font(AppFont.interBold(15))
                                    .foregroundStyle(ProfileTheme.accent)
                                    .padding(.top, 4)
                            } else {
                                Text(text)
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundStyle(Color.white.opacity(0.90))
                                    .lineSpacing(5)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        case .bullets(let items):
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                                    HStack(alignment: .top, spacing: 10) {
                                        Circle()
                                            .fill(ProfileTheme.accent)
                                            .frame(width: 5, height: 5)
                                            .padding(.top, 7)
                                        Text(item)
                                            .font(.system(size: 15, weight: .regular))
                                            .foregroundStyle(Color.white.opacity(0.90))
                                            .lineSpacing(4)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        case .contact(let label, let value):
                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text("\(label):")
                                    .font(AppFont.interBold(14))
                                    .foregroundStyle(ProfileTheme.muted)
                                Text(value)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(sectionChrome)
            }
        }
    }

    private var sectionChrome: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(Color(red: 6 / 255, green: 18 / 255, blue: 40 / 255).opacity(0.88))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(ProfileTheme.cardBorder.opacity(0.75), lineWidth: 1)
            )
    }

    private func isSubhead(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count < 40, !trimmed.contains(".") else { return false }
        return true
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
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Spacer()
                    Color.clear.frame(width: 36, height: 36)
                }
                .padding(.horizontal, ProfileTheme.contentInset)
                .padding(.top, 6)

                ScrollView {
                    Text(bodyText)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.white.opacity(0.85))
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .profileCard()
                        .padding(.horizontal, ProfileTheme.contentInset)
                        .padding(.top, 18)
                        .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
    }
}
