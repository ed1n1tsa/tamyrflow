import SwiftUI

/// Figma iPhone 17 — «Важная информация» (disabled → accepted).
struct ImportantInfoView: View {
    @Binding var isAccepted: Bool
    var onNext: () -> Void
    var onClose: (() -> Void)? = nil

    private let paragraphs: [String] = [
        "TamyrFlow — приложение для отслеживания физической активности и общего самочувствия.",
        "Приложение носит исключительно информационный и оздоровительный характер и не является медицинским изделием.",
        "Данные, получаемые с умных часов, предназначены для личного ознакомления и могут содержать погрешности.",
        "TamyrFlow не предназначен для диагностики, лечения, профилактики заболеваний или принятия медицинских решений.",
        "Информация в приложении не заменяет консультацию квалифицированного медицинского специалиста.",
        "Нажимая «Понимаю и продолжить», вы подтверждаете, что ознакомились с данной информацией и понимаете ограничения приложения."
    ]

    var body: some View {
        ZStack {
            OnboardingBackgroundView(blurred: true)

            VStack {
                Spacer(minLength: 24)

                modalCard
                    .padding(.horizontal, 22)

                Spacer(minLength: 24)
            }
        }
    }

    private var modalCard: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button {
                    onClose?()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppTheme.brandBlue)
                        .frame(width: 28, height: 28)
                }
                .buttonStyle(.plain)
            }
            .padding(.top, 14)
            .padding(.trailing, 14)

            Text("ВАЖНАЯ ИНФОРМАЦИЯ")
                .font(.system(size: 15, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(.black)
                .multilineTextAlignment(.center)
                .padding(.top, 2)
                .padding(.horizontal, 20)

            ZStack {
                Text("TAMYR FLOW")
                    .font(.system(size: 42, weight: .heavy))
                    .foregroundStyle(Color.black.opacity(0.04))
                    .rotationEffect(.degrees(-8))
                    .allowsHitTesting(false)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(paragraphs, id: \.self) { line in
                            Text(line)
                                .font(.system(size: 13, weight: .regular))
                                .foregroundStyle(Color.black.opacity(0.88))
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 8)
                }
            }
            .padding(.horizontal, 22)
            .frame(maxHeight: 360)

            Button {
                withAnimation(.easeInOut(duration: 0.15)) {
                    isAccepted.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .strokeBorder(isAccepted ? AppTheme.brandBlue : Color.black.opacity(0.35), lineWidth: 2)
                            .frame(width: 22, height: 22)
                        if isAccepted {
                            Circle()
                                .fill(AppTheme.brandBlue)
                                .frame(width: 12, height: 12)
                        }
                    }
                    Text("Понимаю и продолжить")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(.black)
                    Spacer(minLength: 0)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 22)
            .padding(.top, 10)

            Button(action: onNext) {
                Text("ДАЛЕЕ")
                    .font(.system(size: 16, weight: .bold))
                    .tracking(1.0)
                    .foregroundStyle(isAccepted ? Color.white : AppTheme.onboardingButtonDisabledText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(
                        Capsule(style: .continuous)
                            .fill(isAccepted ? AppTheme.brandBlue : AppTheme.onboardingButtonDisabled)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!isAccepted)
            .padding(.horizontal, 22)
            .padding(.top, 16)
            .padding(.bottom, 22)
        }
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.white)
        )
        .shadow(color: .black.opacity(0.25), radius: 24, y: 10)
    }
}

#Preview("Off") {
    ImportantInfoView(isAccepted: .constant(false), onNext: {})
}

#Preview("On") {
    ImportantInfoView(isAccepted: .constant(true), onNext: {})
}
