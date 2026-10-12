import SwiftUI

/// Figma login — after «НАЧАТЬ». Auth wiring comes next; UI matches refs 1–2.
struct LoginView: View {
    var onLogin: (_ email: String, _ password: String) -> Void
    var onNoAccount: () -> Void = {}
    var onForgotPassword: () -> Void = {}

    @State private var email = ""
    @State private var password = ""
    @State private var acceptedTerms = false

    private let fieldHeight: CGFloat = 52

    var body: some View {
        ZStack {
            loginBackground

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    brandHeader
                        .padding(.top, 20)

                    Text("ВОЙДИТЕ В АККАУНТ")
                        .font(AppFont.interBold(26))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .padding(.top, 36)

                    VStack(spacing: 14) {
                        authField(placeholder: "ПОЧТА", text: $email, isSecure: false)
                        authField(placeholder: "ПАРОЛЬ", text: $password, isSecure: true)
                    }
                    .padding(.top, 28)

                    HStack {
                        Button(action: onNoAccount) {
                            Text("Нет аккаунта?")
                                .font(AppFont.interBold(13))
                                .foregroundStyle(AppTheme.authLink)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button(action: onForgotPassword) {
                            Text("Забыли пароль?")
                                .font(AppFont.interBold(13))
                                .foregroundStyle(AppTheme.authLink)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.top, 14)

                    termsRow
                        .padding(.top, 28)

                    Button {
                        guard canSubmit else { return }
                        onLogin(email.trimmingCharacters(in: .whitespacesAndNewlines), password)
                    } label: {
                        Text("ВОЙТИ")
                            .font(AppFont.interBold(17))
                            .tracking(1.0)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(canSubmit ? AppTheme.authPrimaryButton : AppTheme.authPrimaryButton.opacity(0.45))
                            )
                    }
                    .buttonStyle(.plain)
                    .disabled(!canSubmit)
                    .padding(.top, 28)
                    .padding(.bottom, 40)
                }
                .padding(.horizontal, 28)
            }
        }
    }

    private var canSubmit: Bool {
        acceptedTerms
            && !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !password.isEmpty
    }

    private var loginBackground: some View {
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
                .font(AppFont.interBold(18))
                .tracking(1.2)
                .foregroundStyle(.white)
        }
    }

    private func authField(placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        Group {
            if isSecure {
                SecureField("", text: text, prompt: fieldPrompt(placeholder))
            } else {
                TextField("", text: text, prompt: fieldPrompt(placeholder))
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
            }
        }
        .font(AppFont.interBold(15))
        .foregroundStyle(.black)
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
        .frame(height: fieldHeight)
        .background(
            Capsule(style: .continuous)
                .fill(Color.white)
        )
    }

    private func fieldPrompt(_ text: String) -> Text {
        Text(text)
            .font(AppFont.interBold(15))
            .foregroundStyle(AppTheme.authFieldPlaceholder)
    }

    private var termsRow: some View {
        HStack(alignment: .top, spacing: 12) {
            Button {
                acceptedTerms.toggle()
            } label: {
                ZStack {
                    Circle()
                        .strokeBorder(Color.white, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if acceptedTerms {
                        Circle()
                            .fill(AppTheme.authLink)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 2)

            (
                Text("Я ознакомился(-ась) и согласен(-на) с ").foregroundColor(.white)
                + Text("Политикой конфиденциальности").foregroundColor(AppTheme.authLink)
                + Text(" и ").foregroundColor(.white)
                + Text("Условиями использования").foregroundColor(AppTheme.authLink)
                + Text(" приложения TamyrFlow.").foregroundColor(.white)
            )
            .font(AppFont.interBold(12))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    LoginView(onLogin: { _, _ in })
}
