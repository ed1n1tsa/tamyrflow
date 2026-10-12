import SwiftUI

enum OnboardingStep: Equatable {
    case importantInfo
    case welcome
}

/// Entry flow: Important Info → Welcome «НАЧАТЬ» → main app.
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
                    onFinished()
                }
                .transition(.opacity.combined(with: .move(edge: .trailing)))
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
