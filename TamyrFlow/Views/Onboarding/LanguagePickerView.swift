import SwiftUI

/// Compact KZ / RU / ENG chips (welcome top-trailing).
struct LanguagePickerView: View {
    @EnvironmentObject private var language: LanguageStore

    var body: some View {
        HStack(spacing: 6) {
            ForEach(AppLanguageCode.allCases) { code in
                Button {
                    withAnimation(.easeInOut(duration: 0.15)) {
                        language.set(code)
                    }
                } label: {
                    Text(code.shortLabel)
                        .font(AppFont.interBold(12))
                        .foregroundStyle(language.code == code ? AppTheme.authLink : Color.white.opacity(0.78))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(language.code == code ? Color.white.opacity(0.16) : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityLabel("Language")
    }
}
