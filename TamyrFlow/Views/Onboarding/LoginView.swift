import SwiftUI

/// Figma login — after «НАЧАТЬ». Supabase sign-in wired.
struct LoginView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var language: LanguageStore

    var onLoggedIn: () -> Void
    var onNoAccount: () -> Void
    var onForgotPassword: (String) -> Void = { _ in }

    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var acceptedTerms = false

    private let fieldHeight: CGFloat = 54

    var body: some View {
        ZStack {
            authBackground

            VStack(spacing: 0) {
                brandHeader
                    .padding(.top, 12)

                Spacer(minLength: 24)

                VStack(spacing: 0) {
                    Text(L10n.Auth.loginTitle)
                        .font(AppFont.interBold(28))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .id(language.code)

                    VStack(spacing: 14) {
                        authField(placeholder: L10n.Auth.email, text: $email)
                        passwordField
                    }
                    .padding(.top, 26)

                    HStack {
                        Button(action: onNoAccount) {
                            Text(L10n.Auth.noAccount)
                                .font(AppFont.interBold(14))
                                .foregroundStyle(AppTheme.authLink)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            onForgotPassword(email.trimmingCharacters(in: .whitespacesAndNewlines))
                        } label: {
                            Text(L10n.Auth.forgotPassword)
                                .font(AppFont.interBold(14))
                                .foregroundStyle(AppTheme.authLink)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 16)

                    termsRow
                        .padding(.top, 26)

                    if let err = auth.lastError {
                        Text(err)
                            .font(AppFont.interBold(13))
                            .foregroundStyle(AppTheme.danger)
                            .multilineTextAlignment(.center)
                            .padding(.top, 12)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            if auth.isBusy {
                                ProgressView().tint(.white)
                            }
                            Text(L10n.Auth.login)
                                .font(AppFont.interBold(18))
                                .tracking(1.0)
                                .foregroundStyle(.white)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            Capsule(style: .continuous)
                                .fill(canSubmit ? AppTheme.authPrimaryButton : AppTheme.authPrimaryButton.opacity(0.45))
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSubmit || auth.isBusy)
                    .padding(.top, 28)
                }

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 12)
        }
    }

    private var canSubmit: Bool {
        acceptedTerms
            && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
    }

    private var authBackground: some View {
        GeometryReader { geo in
            ZStack {
                Image("LoginBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                AppTheme.onboardingTopScrim
                    .opacity(AppTheme.onboardingTopScrimOpacity)
            }
        }
        .ignoresSafeArea()
    }

    private var brandHeader: some View {
        HStack(spacing: 10) {
            BrandLogoMark()
            Text("TAMYR FLOW")
                .font(AppFont.interBold(20))
                .tracking(1.2)
                .foregroundStyle(.white)
        }
    }

    private func authField(placeholder: String, text: Binding<String>) -> some View {
        TextField("", text: text, prompt: prompt(placeholder))
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .autocorrectionDisabled()
            .font(AppFont.interBold(16))
            .foregroundStyle(.black)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: fieldHeight)
            .background(Capsule(style: .continuous).fill(Color.white))
    }

    private var passwordField: some View {
        HStack(spacing: 8) {
            Group {
                if isPasswordVisible {
                    TextField("", text: $password, prompt: prompt(L10n.Auth.password))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField("", text: $password, prompt: prompt(L10n.Auth.password))
                }
            }
            .font(AppFont.interBold(16))
            .foregroundStyle(.black)
            .textContentType(.password)

            Button {
                isPasswordVisible.toggle()
            } label: {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.brandBlue.opacity(0.75))
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
        }
        .padding(.leading, 22)
        .padding(.trailing, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: fieldHeight)
        .background(Capsule(style: .continuous).fill(Color.white))
    }

    private func prompt(_ text: String) -> Text {
        Text(text)
            .font(AppFont.interBold(16))
            .foregroundStyle(AppTheme.authFieldPlaceholder)
    }

    private var termsRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Button { acceptedTerms.toggle() } label: {
                ZStack {
                    Circle().strokeBorder(Color.white, lineWidth: 2).frame(width: 22, height: 22)
                    if acceptedTerms {
                        Circle().fill(AppTheme.authLink).frame(width: 12, height: 12)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            (
                Text(L10n.Auth.termsPrefix).foregroundColor(.white)
                + Text(L10n.Auth.privacy).foregroundColor(AppTheme.authLink)
                + Text(L10n.Auth.termsAnd).foregroundColor(.white)
                + Text(L10n.Auth.terms).foregroundColor(AppTheme.authLink)
                + Text(L10n.Auth.termsSuffix).foregroundColor(.white)
            )
            .font(AppFont.interBold(13))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .id(language.code)
        }
    }

    private func submit() async {
        auth.lastError = nil
        do {
            try await auth.signIn(
                email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                password: password
            )
            onLoggedIn()
        } catch {
            auth.lastError = error.localizedDescription
        }
    }
}
