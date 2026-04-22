import SwiftUI

struct LoginView: View {
    @ObservedObject var auth: AuthViewModel
    @State private var isSignUp = false

    var body: some View {
        VStack(spacing: 14) {
            Spacer(minLength: 20)

            Text(isSignUp ? "Регистрация" : "Вход")
                .font(.system(size: 26, weight: .bold))

            Text(isSignUp ? "Создай аккаунт в Supabase" : "Логин и пароль из Supabase")
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)

            VStack(spacing: 10) {

                if isSignUp {
                    TextField("Username", text: $auth.username) // ✅ ВАЖНО: $auth.username
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding(12)
                        .background(Color.black.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                TextField("Email", text: $auth.email) // ✅ ВАЖНО: $auth.email (а не auth.$email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                    .padding(12)
                    .background(Color.black.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                SecureField("Пароль", text: $auth.password) // ✅ $auth.password
                    .padding(12)
                    .background(Color.black.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if isSignUp {
                    SecureField("Повтори пароль", text: $auth.confirmPassword) // ✅ $auth.confirmPassword
                        .padding(12)
                        .background(Color.black.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }

            if let err = auth.errorText {
                Text(err)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.red)
                    .padding(.top, 4)
            }

            Button {
                Task {
                    if isSignUp {
                        await auth.signUp()
                    } else {
                        await auth.signIn()
                    }
                }
            } label: {
                Text(buttonTitle)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.black.opacity(0.85))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .disabled(isButtonDisabled)

            Button {
                withAnimation(.spring()) {
                    isSignUp.toggle()
                    auth.errorText = nil
                    auth.confirmPassword = ""
                    auth.username = ""
                }
            } label: {
                Text(isSignUp ? "Уже есть аккаунт? Войти" : "Нет аккаунта? Зарегистрироваться")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppColors.orange)
                    .padding(.top, 6)
            }
            .buttonStyle(.plain)

            Spacer()
        }
        .padding(.horizontal, 16)
    }

    private var buttonTitle: String {
        if auth.loading { return isSignUp ? "Создаём..." : "Входим..." }
        return isSignUp ? "Создать аккаунт" : "Войти"
    }

    private var isButtonDisabled: Bool {
        if auth.loading { return true }
        if auth.email.isEmpty || auth.password.isEmpty { return true }
        if isSignUp {
            if auth.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return true }
            if auth.password.count < 6 { return true }
            if auth.confirmPassword.isEmpty { return true }
        }
        return false
    }
}
