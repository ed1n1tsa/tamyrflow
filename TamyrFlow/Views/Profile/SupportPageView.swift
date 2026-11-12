import SwiftUI

struct SupportPageView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            ProfileSetupBackground()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(L10n.Support.subtitle)
                            .font(AppFont.interBold(13))
                            .foregroundStyle(ProfileTheme.muted)
                            .fixedSize(horizontal: false, vertical: true)

                        contactCard

                        sectionTitle(L10n.Support.faqTitle)
                        faqCard(title: L10n.Support.faq1Title, body: L10n.Support.faq1Body)
                        faqCard(title: L10n.Support.faq2Title, body: L10n.Support.faq2Body)
                        faqCard(title: L10n.Support.faq3Title, body: L10n.Support.faq3Body)
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
            Text(L10n.Support.title)
                .font(AppFont.interBold(17))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(AppFont.interBold(13))
            .foregroundStyle(ProfileTheme.muted)
            .padding(.top, 6)
    }

    private var contactCard: some View {
        Button {
            if let url = URL(string: "mailto:\(L10n.About.contactEmail)") {
                openURL(url)
            }
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "envelope.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(ProfileTheme.accent)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(ProfileTheme.accent.opacity(0.16)))
                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.Support.emailTitle)
                        .font(AppFont.interBold(15))
                        .foregroundStyle(.white)
                    Text(L10n.About.contactEmail)
                        .font(AppFont.interBold(13))
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
    }

    private func faqCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.interBold(15))
                .foregroundStyle(.white)
            Text(body)
                .font(AppFont.interBold(13))
                .foregroundStyle(Color.white.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .profileCard()
    }
}
