import SwiftUI

/// Checkbox + localized Privacy Policy / Terms of Use links that open the in-app legal documents.
struct AuthTermsConsentRow: View {
    @Binding var accepted: Bool
    @EnvironmentObject private var language: LanguageStore

    @State private var presentedDocument: LegalDocumentKind?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button { accepted.toggle() } label: {
                ZStack {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if accepted {
                        Circle()
                            .fill(AppTheme.authLink)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.Auth.terms)
            .padding(.top, 2)

            consentText
                .font(AppFont.interBold(13))
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .environment(\.openURL, OpenURLAction { url in
                    switch url.scheme?.lowercased() {
                    case "tamyrflow-privacy":
                        presentedDocument = .privacyPolicy
                        return .handled
                    case "tamyrflow-terms":
                        presentedDocument = .terms
                        return .handled
                    default:
                        return .systemAction
                    }
                })
                .id(language.code)
        }
        .sheet(item: $presentedDocument) { kind in
            NavigationStack {
                LegalDocumentView(kind: kind)
                    .environmentObject(language)
            }
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    private var consentText: Text {
        let privacyURL = URL(string: "tamyrflow-privacy://open")!
        let termsURL = URL(string: "tamyrflow-terms://open")!

        var attributed = AttributedString(L10n.Auth.termsPrefix)
        attributed.foregroundColor = .white

        var privacy = AttributedString(L10n.Auth.privacy)
        privacy.link = privacyURL
        privacy.foregroundColor = AppTheme.authLink
        attributed.append(privacy)

        var and = AttributedString(L10n.Auth.termsAnd)
        and.foregroundColor = .white
        attributed.append(and)

        var terms = AttributedString(L10n.Auth.terms)
        terms.link = termsURL
        terms.foregroundColor = AppTheme.authLink
        attributed.append(terms)

        var suffix = AttributedString(L10n.Auth.termsSuffix)
        suffix.foregroundColor = .white
        attributed.append(suffix)

        return Text(attributed)
    }
}
