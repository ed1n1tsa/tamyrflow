import Combine
import SwiftUI

/// Restore password: email → send OTP popup → 8-digit code → new password (Figma).
struct ForgotPasswordView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var language: LanguageStore

    var initialEmail: String = ""
    var onDone: () -> Void
    var onBackToLogin: () -> Void

    @State private var email = ""
    @State private var digits: [String] = Array(repeating: "", count: Self.codeLength)
    @State private var phase: Phase = .otp
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var showMailPopup = false
    @State private var resendSecondsLeft = 0
    @State private var didAutoSend = false
    @FocusState private var focusedDigit: Int?

    private enum Phase {
        case otp
        case newPassword
    }

    private static let codeLength = 8
    private static let resendCooldown = 60
    private let fieldHeight: CGFloat = 54

    private var code: String { digits.joined() }

    private var trimmedEmail: String {
        email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private var canResend: Bool {
        !trimmedEmail.isEmpty && resendSecondsLeft == 0 && !auth.isBusy
    }

    private var canSubmitOTP: Bool {
        !trimmedEmail.isEmpty
            && code.count == Self.codeLength
            && code.allSatisfy(\.isNumber)
            && !auth.isBusy
    }

    private var canSavePassword: Bool {
        newPassword.count >= 6 && newPassword == confirmPassword && !auth.isBusy
    }

    var body: some View {
        ZStack {
            authBackground

            VStack(spacing: 0) {
                Spacer(minLength: 36)

                Group {
                    switch phase {
                    case .otp:
                        otpContent
                    case .newPassword:
                        newPasswordContent
                    }
                }
                .id(language.code)

                Spacer(minLength: 36)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            if showMailPopup {
                mailSentPopup
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(2)
            }
        }
        .animation(.easeInOut(duration: 0.22), value: showMailPopup)
        .onAppear {
            if email.isEmpty { email = initialEmail }
            if !trimmedEmail.isEmpty, !didAutoSend {
                didAutoSend = true
                Task { await sendCode(showPopup: true) }
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if resendSecondsLeft > 0 {
                resendSecondsLeft -= 1
            }
        }
    }

    // MARK: - OTP

    private var otpContent: some View {
        VStack(spacing: 0) {
            Text(L10n.Auth.forgotTitle)
                .font(AppFont.interBold(24))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.85)
                .lineLimit(2)
                .frame(maxWidth: .infinity)

            emailField
                .padding(.top, 24)

            codeBoxes
                .padding(.top, 18)

            Text(hintText)
                .font(AppFont.interBold(12))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.top, 14)
                .fixedSize(horizontal: false, vertical: true)

            if let err = auth.lastError {
                Text(err)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(AppTheme.danger)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }

            HStack(spacing: 10) {
                resendButton
                actionButton(
                    title: L10n.Auth.forgotSubmit,
                    enabled: canSubmitOTP
                ) {
                    Task { await submitOTP() }
                }
            }
            .padding(.top, 22)

            Button(action: onBackToLogin) {
                Text(L10n.Auth.haveAccount)
                    .font(AppFont.interBold(14))
                    .foregroundStyle(AppTheme.authLink)
            }
            .buttonStyle(.plain)
            .padding(.top, 18)
        }
    }

    private var hintText: String {
        if trimmedEmail.isEmpty {
            return L10n.Auth.forgotHintEmpty
        }
        return String(format: L10n.Auth.forgotHintFormat, trimmedEmail)
    }

    private var emailField: some View {
        TextField("", text: $email, prompt: prompt(L10n.Auth.email))
            .textInputAutocapitalization(.never)
            .keyboardType(.emailAddress)
            .textContentType(.emailAddress)
            .autocorrectionDisabled()
            .font(AppFont.interBold(15))
            .foregroundStyle(.black)
            .padding(.horizontal, 20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: fieldHeight)
            .background(Capsule(style: .continuous).fill(Color.white))
            .onSubmit {
                Task { await sendCode(showPopup: true) }
            }
    }

    private var codeBoxes: some View {
        GeometryReader { geo in
            let spacing: CGFloat = 6
            let totalSpacing = spacing * CGFloat(Self.codeLength - 1)
            let side = min(44, max(30, (geo.size.width - totalSpacing) / CGFloat(Self.codeLength)))

            HStack(spacing: spacing) {
                ForEach(0..<Self.codeLength, id: \.self) { index in
                    TextField("", text: Binding(
                        get: { digits[index] },
                        set: { handleDigitChange(index, $0) }
                    ))
                    .keyboardType(.numberPad)
                    .textContentType(.oneTimeCode)
                    .multilineTextAlignment(.center)
                    .font(AppFont.interBold(side > 36 ? 18 : 15))
                    .foregroundStyle(.black)
                    .frame(width: side, height: side + 8)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.white)
                    )
                    .focused($focusedDigit, equals: index)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 52)
    }

    private func handleDigitChange(_ index: Int, _ value: String) {
        let filtered = value.filter(\.isNumber)

        if filtered.count > 1 {
            let chars = Array(filtered.prefix(Self.codeLength))
            for i in 0..<Self.codeLength {
                digits[i] = i < chars.count ? String(chars[i]) : ""
            }
            focusedDigit = chars.count >= Self.codeLength ? Self.codeLength - 1 : chars.count
            return
        }

        digits[index] = filtered.isEmpty ? "" : String(filtered.suffix(1))
        if !filtered.isEmpty {
            if index < Self.codeLength - 1 {
                focusedDigit = index + 1
            } else {
                focusedDigit = nil
            }
        } else if index > 0 {
            focusedDigit = index - 1
        }
    }

    private var resendButton: some View {
        let title: String = {
            if resendSecondsLeft > 0 {
                return "\(L10n.Auth.forgotResend)\n\(resendSecondsLeft)с"
            }
            return L10n.Auth.forgotResend
        }()

        return Button {
            Task { await sendCode(showPopup: true) }
        } label: {
            Text(title)
                .font(AppFont.interBold(12))
                .tracking(0.3)
                .foregroundStyle(.white.opacity(canResend ? 1 : 0.75))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(canResend ? AppTheme.authPrimaryButton : AppTheme.authPrimaryButton.opacity(0.35))
                )
        }
        .buttonStyle(.plain)
        .disabled(!canResend)
    }

    // MARK: - New password (Figma 4)

    private var newPasswordContent: some View {
        VStack(spacing: 0) {
            Text(L10n.Auth.newPasswordTitle)
                .font(AppFont.interBold(24))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            // No eye toggle on this Figma — clean capsules.
            SecureField("", text: $newPassword, prompt: prompt(L10n.Auth.newPassword))
                .font(AppFont.interBold(15))
                .foregroundStyle(.black)
                .textContentType(.newPassword)
                .padding(.horizontal, 22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: fieldHeight)
                .background(Capsule(style: .continuous).fill(Color.white))
                .padding(.top, 28)

            SecureField("", text: $confirmPassword, prompt: prompt(L10n.Auth.confirmPassword))
                .font(AppFont.interBold(15))
                .foregroundStyle(.black)
                .textContentType(.newPassword)
                .padding(.horizontal, 22)
                .frame(maxWidth: .infinity, alignment: .leading)
                .frame(height: fieldHeight)
                .background(Capsule(style: .continuous).fill(Color.white))
                .padding(.top, 14)

            if let err = auth.lastError {
                Text(err)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(AppTheme.danger)
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }

            HStack {
                Spacer(minLength: 40)
                Button {
                    Task { await saveNewPassword() }
                } label: {
                    Text(L10n.Auth.savePassword)
                        .font(AppFont.interBold(15))
                        .tracking(0.6)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(canSavePassword ? AppTheme.authPrimaryButton : AppTheme.authPrimaryButton.opacity(0.45))
                        )
                }
                .buttonStyle(.plain)
                .disabled(!canSavePassword)
            }
            .padding(.top, 28)
        }
    }

    // MARK: - Popup

    private var mailSentPopup: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { showMailPopup = false }

            VStack(spacing: 16) {
                Text("TAMYR FLOW")
                    .font(AppFont.interBold(12))
                    .tracking(2)
                    .foregroundStyle(AppTheme.authLink)

                Text(L10n.Auth.mailPopupTitle)
                    .font(AppFont.interBold(20))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)

                Text(String(format: L10n.Auth.mailPopupBody, trimmedEmail))
                    .font(AppFont.interBold(14))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .multilineTextAlignment(.center)

                Button {
                    showMailPopup = false
                    focusedDigit = 0
                } label: {
                    Text(L10n.Auth.mailPopupOK)
                        .font(AppFont.interBold(15))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(
                            Capsule(style: .continuous)
                                .fill(AppTheme.authPrimaryButton)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.brandBlueDeep)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(AppTheme.authLink.opacity(0.35), lineWidth: 1)
            )
            .padding(.horizontal, 28)
        }
    }

    // MARK: - Chrome

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
            .font(AppFont.interBold(15))
            .foregroundStyle(AppTheme.authFieldPlaceholder)
    }

    private func actionButton(title: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.interBold(12))
                .tracking(0.3)
                .foregroundStyle(.white.opacity(enabled ? 1 : 0.7))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(enabled ? AppTheme.authPrimaryButton : AppTheme.authPrimaryButton.opacity(0.35))
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: - Actions

    private func sendCode(showPopup: Bool) async {
        auth.lastError = nil
        guard !trimmedEmail.isEmpty else {
            auth.lastError = L10n.Auth.forgotNeedEmail
            return
        }
        guard resendSecondsLeft == 0 else { return }

        do {
            try await auth.sendPasswordRecovery(email: trimmedEmail)
            resendSecondsLeft = Self.resendCooldown
            digits = Array(repeating: "", count: Self.codeLength)
            if showPopup {
                showMailPopup = true
            }
        } catch {
            auth.lastError = error.localizedDescription
        }
    }

    private func submitOTP() async {
        auth.lastError = nil
        guard canSubmitOTP else { return }

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
