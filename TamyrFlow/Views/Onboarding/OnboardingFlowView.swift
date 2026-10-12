import SwiftUI

enum OnboardingStep: Equatable {
    case importantInfo
    case welcome
    case login
}

/// Important Info → Welcome «НАЧАТЬ» → Login (Supabase auth next).
struct OnboardingFlowView: View {
    var onFinished: () -> Void

    @State private var step: OnboardingStep = .importantInfo
    @State private var isAccepted = false

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
                    onLogin: { _, _ in
                        // TODO: Supabase Auth — wire next.
                        // Temporary: allow continuing into app until auth is connected.
                        OnboardingStorage.markCompleted()
                        onFinished()
                    },
                    onNoAccount: {
                        // TODO: registration screen
                    },
                    onForgotPassword: {
                        // TODO: password reset
                    }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.28), value: step)
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
