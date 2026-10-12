import SwiftUI

/// Figma «Восстановить пароль»: email + 4-digit OTP + resend/submit.
struct ForgotPasswordView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var language: LanguageStore

    var initialEmail: String = ""
    var onDone: () -> Void
    var onBackToLogin: () -> Void

    @State private var email = ""
    @State private var digits: [String] = ["", "", "", ""]
    @State private var codeSent = false
    @State private var infoMessage: String?
    @State private var phase: Phase = .otp
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var isPasswordVisible = false
    @FocusState private var focusedDigit: Int?

    private enum Phase {
        case otp
        case newPassword
    }

    private let fieldHeight: CGFloat = 54
    private let codeBoxSize: CGFloat = 58

    private var code: String { digits.joined() }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    var body: some View {
        ZStack {
            authBackground

            VStack(spacing: 0) {
                Spacer(minLength: 40)

                Group {
                    switch phase {
                    case .otp:
                        otpContent
                    case .newPassword:
                        newPasswordContent
                    }
                }
                .id(language.code)

                Spacer(minLength: 40)
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 12)
        }
        .onAppear {
            if email.isEmpty { email = initialEmail }
        }
    }

    // MARK: - OTP phase (Figma)

    private var otpContent: some View {
        VStack(spacing: 0) {
            Text(L10n.Auth.forgotTitle)
                .font(AppFont.interBold(26))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            emailField
                .padding(.top, 28)

            codeBoxes
                .padding(.top, 22)

            Text(hintText)
                .font(AppFont.interBold(13))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 18)
                .fixedSize(horizontal: false, vertical: true)

            if let infoMessage {
                Text(infoMessage)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(AppTheme.authLink)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }

            if let err = auth.lastError {
                Text(err)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(AppTheme.danger)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)
            }

            HStack(spacing: 12) {
                actionButton(
                    title: L10n.Auth.forgotResend,
                    enabled: !trimmedEmail.isEmpty && !auth.isBusy
                ) {
                    Task { await resendCode() }
                }

                actionButton(
                    title: L10n.Auth.forgotSubmit,
                    enabled: canSubmitOTP && !auth.isBusy
                ) {
                    Task { await submitOTP() }
                }
            }
            .padding(.top, 26)

            Button(action: onBackToLogin) {
                Text(L10n.Auth.haveAccount)
                    .font(AppFont.interBold(14))
                    .foregroundStyle(AppTheme.authLink)
            }
            .buttonStyle(.plain)
            .padding(.top, 20)
        }
    }

    private var hintText: String {
        if trimmedEmail.isEmpty {
            return L10n.Auth.forgotHintEmpty
        }
        return String(format: L10n.Auth.forgotHintFormat, trimmedEmail)
    }

    private var canSubmitOTP: Bool {
        !trimmedEmail.isEmpty && code.count == 4 && code.allSatisfy(\.isNumber)
    }

    private var emailField: some View {
        TextField("", text: $email, prompt: prompt(L10n.Auth.email))
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocorrectionDisabled()
            .font(AppFont.interBold(16))
            .foregroundStyle(.black)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: fieldHeight)
            .background(Capsule(style: .continuous).fill(Color.white))
            .onSubmit {
                Task { await resendCode() }
            }
    }

    private var codeBoxes: some View {
        HStack(spacing: 12) {
            ForEach(0..<4, id: \.self) { index in
                TextField("", text: Binding(
                    get: { digits[index] },
                    set: { handleDigitChange(index, $0) }
                ))
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .multilineTextAlignment(.center)
                .font(AppFont.interBold(22))
                .foregroundStyle(.black)
                .frame(width: codeBoxSize, height: codeBoxSize)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(Color.white)
                )
                .focused($focusedDigit, equals: index)
            }
        }
    }

    private func handleDigitChange(_ index: Int, _ value: String) {
        let filtered = value.filter(\.isNumber)

        // Paste full code into first box
        if filtered.count > 1 {
            let chars = Array(filtered.prefix(4))
            for i in 0..<4 {
                digits[i] = i < chars.count ? String(chars[i]) : ""
            }
            focusedDigit = chars.count >= 4 ? 3 : chars.count
            return
        }

        digits[index] = filtered.isEmpty ? "" : String(filtered.suffix(1))
        if !filtered.isEmpty {
            if index < 3 {
                focusedDigit = index + 1
            } else {
                focusedDigit = nil
            }
        } else if index > 0 {
            focusedDigit = index - 1
        }
    }

    // MARK: - New password phase

    private var newPasswordContent: some View {
        VStack(spacing: 0) {
            Text(L10n.Auth.newPasswordTitle)
                .font(AppFont.interBold(26))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            passwordField(text: $newPassword, placeholder: L10n.Auth.newPassword)
                .padding(.top, 28)

            passwordField(text: $confirmPassword, placeholder: L10n.Auth.confirmPassword)
                .padding(.top, 14)

            if let err = auth.lastError {
                Text(err)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(AppTheme.danger)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }

            actionButton(
                title: L10n.Auth.savePassword,
                enabled: canSavePassword && !auth.isBusy
            ) {
                Task { await saveNewPassword() }
            }
            .padding(.top, 28)
        }
    }

    private var canSavePassword: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword
    }

    private func passwordField(text: Binding<String>, placeholder: String) -> some View {
        HStack(spacing: 8) {
            Group {
                if isPasswordVisible {
                    TextField("", text: text, prompt: prompt(placeholder))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } else {
                    SecureField("", text: text, prompt: prompt(placeholder))
                }
            }
            .font(AppFont.interBold(16))
            .foregroundStyle(.black)
            .textContentType(.newPassword)

            Button { isPasswordVisible.toggle() } label: {
                Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.brandBlue.opacity(0.75))
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
        }
        .padding(.leading, 22)
        .padding(.trailing, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: fieldHeight)
        .background(Capsule(style: .continuous).fill(Color.white))
    }

    // MARK: - Shared chrome

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

    private func prompt(_ text: String) -> Text {
        Text(text)
            .font(AppFont.interBold(16))
            .foregroundStyle(AppTheme.authFieldPlaceholder)
    }

    private func actionButton(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.interBold(13))
                .tracking(0.4)
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(enabled ? AppTheme.authPrimaryButton : AppTheme.authPrimaryButton.opacity(0.45))
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: - Actions

    private func resendCode() async {
        auth.lastError = nil
        infoMessage = nil
        guard !trimmedEmail.isEmpty else {
            auth.lastError = L10n.Auth.forgotNeedEmail
            return
        }
        do {
            try await auth.sendPasswordRecovery(email: trimmedEmail)
            codeSent = true
            infoMessage = L10n.Auth.forgotCodeSent
            focusedDigit = 0
        } catch {
            auth.lastError = error.localizedDescription
        }
    }

    private func submitOTP() async {
        auth.lastError = nil
        infoMessage = nil

        // First press without a full code → send the email OTP.
        if code.count < 4 {
            await resendCode()
            return
        }

        guard !trimmedEmail.isEmpty else {
            auth.lastError = L10n.Auth.forgotNeedEmail
            return
        }

        do {
            try await auth.verifyRecoveryOTP(email: trimmedEmail, token: code)
            withAnimation(.easeInOut(duration: 0.25)) {
                phase = .newPassword
            }
        } catch {
            auth.lastError = error.localizedDescription
        }
    }

    private func saveNewPassword() async {
        auth.lastError = nil
        guard canSavePassword else {
            auth.lastError = L10n.Auth.passwordMismatch
            return
        }
        do {
            try await auth.updatePassword(newPassword)
            onDone()
        } catch {
            auth.lastError = error.localizedDescription
        }
    }
}
