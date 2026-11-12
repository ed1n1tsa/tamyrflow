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
                    .padding(.top, 10)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationBarHidden(true)
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
        VStack(alignment: .leading, spacing: 14) {
            Text(kind.title)
                .font(AppFont.interBold(28))
                .foregroundStyle(.white)

            ForEach(Array(kind.paragraphs.enumerated()), id: \.offset) { _, text in
                Text(text)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.white.opacity(0.86))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .profileCard()
            }
        }
    }

    /// Continuous document layout — no per-section cards, compact readable spacing.
    private func richLegalBody(
        title: String,
        updated: String,
        sections: [LegalRichDocument.Section]
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(AppFont.interBold(22))
                .foregroundStyle(.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(updated)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(ProfileTheme.muted)
                .padding(.top, 6)
                .padding(.bottom, 14)

            ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
                Text(section.title)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, index == 0 ? 0 : 16)
                    .padding(.bottom, 6)

                ForEach(Array(section.blocks.enumerated()), id: \.offset) { _, block in
                    switch block {
                    case .paragraph(let text):
                        if isSubhead(text) {
                            Text(text)
                                .font(AppFont.interBold(14))
                                .foregroundStyle(.white.opacity(0.95))
                                .padding(.top, 8)
                                .padding(.bottom, 2)
                        } else {
                            Text(text)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundStyle(Color.white.opacity(0.88))
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.bottom, 6)
                        }
                    case .bullets(let items):
                        VStack(alignment: .leading, spacing: 3) {
                            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(Color.white.opacity(0.88))
                                    Text(item)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundStyle(Color.white.opacity(0.88))
                                        .lineSpacing(2)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                        .padding(.bottom, 6)
                    case .contact(let label, let value):
                        Text("\(label): \(value)")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundStyle(Color.white.opacity(0.88))
                            .textSelection(.enabled)
                            .padding(.bottom, 2)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func isSubhead(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count < 40, !trimmed.contains(".") else { return false }
        // Labels like “Bluetooth”, “Персональная информация”, “Технические данные”
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
