import SwiftUI

/// Figma iPhone 17 — «Важная информация» (disabled → accepted).
struct ImportantInfoView: View {
    @EnvironmentObject private var language: LanguageStore
    @Binding var isAccepted: Bool
    var onNext: () -> Void
    var onClose: (() -> Void)? = nil

    private var paragraphs: [String] {
        [
            L10n.ImportantInfo.p1,
            L10n.ImportantInfo.p2,
            L10n.ImportantInfo.p3,
            L10n.ImportantInfo.p4,
            L10n.ImportantInfo.p5,
            L10n.ImportantInfo.p6
        ]
    }

    var body: some View {
        ZStack {
            OnboardingBackgroundView(blurred: true)

            VStack {
                Spacer(minLength: 24)

                modalCard
                    .padding(.horizontal, 22)
                    .id(language.code)

                Spacer(minLength: 24)
            }
        }
    }

    private var modalCard: some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                LanguagePickerView(style: .onLight)
                Spacer(minLength: 8)
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
            .padding(.horizontal, 14)

            Text(L10n.ImportantInfo.title)
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
                        ForEach(Array(paragraphs.enumerated()), id: \.offset) { _, line in
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
                    Text(L10n.ImportantInfo.accept)
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
                Text(L10n.ImportantInfo.next)
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
        .environmentObject(LanguageStore())
}

#Preview("On") {
    ImportantInfoView(isAccepted: .constant(true), onNext: {})
        .environmentObject(LanguageStore())
}
