import SwiftUI

enum OnboardingStep: Equatable {
    case importantInfo
    case welcome
    case login
    case register
    case forgotPassword
}

/// Important Info → Welcome → Login / Register / Forgot password (Supabase Auth).
struct OnboardingFlowView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var language: LanguageStore

    var onFinished: () -> Void

    @State private var step: OnboardingStep = .importantInfo
    @State private var isAccepted = false
    @State private var forgotEmail = ""

    var body: some View {
        ZStack {
            switch step {
            case .importantInfo:
                ImportantInfoView(
                    isAccepted: $isAccepted,
                    onNext: {
                        guard isAccepted else { return }
                        withAnimation(.easeInOut(duration: 0.28)) {
                            step = .welcome
                        }
                    }
                )
                .transition(.opacity)

            case .welcome:
                WelcomeStartView {
                    withAnimation(.easeInOut(duration: 0.28)) {
                        step = .login
                    }
                }
                .transition(.opacity)

            case .login:
                LoginView(
                    onLoggedIn: finish,
                    onNoAccount: {
                        auth.lastError = nil
                        withAnimation(.easeInOut(duration: 0.28)) {
                            step = .register
                        }
                    },
                    onForgotPassword: { email in
                        auth.lastError = nil
                        forgotEmail = email
                        withAnimation(.easeInOut(duration: 0.28)) {
                            step = .forgotPassword
                        }
                    }
                )
                .transition(.opacity)

            case .register:
                RegisterView(
                    onRegistered: finish,
                    onHaveAccount: {
                        auth.lastError = nil
                        withAnimation(.easeInOut(duration: 0.28)) {
                            step = .login
                        }
                    }
                )
                .transition(.opacity)

            case .forgotPassword:
                ForgotPasswordView(
                    initialEmail: forgotEmail,
                    onDone: {
                        auth.lastError = nil
                        withAnimation(.easeInOut(duration: 0.28)) {
                            step = .login
                        }
                    },
                    onBackToLogin: {
                        auth.lastError = nil
                        withAnimation(.easeInOut(duration: 0.28)) {
                            step = .login
                        }
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: step)
        .environmentObject(language)
    }

    private func finish() {
        OnboardingStorage.markCompleted()
        onFinished()
    }
}

enum OnboardingStorage {
    static let completedKey = "tamyrflow.onboarding.completed"

    static var hasCompleted: Bool {
        UserDefaults.standard.bool(forKey: completedKey)
    }

    static func markCompleted() {
        UserDefaults.standard.set(true, forKey: completedKey)
    }

#if DEBUG
    static func reset() {
        UserDefaults.standard.removeObject(forKey: completedKey)
    }
#endif
}
