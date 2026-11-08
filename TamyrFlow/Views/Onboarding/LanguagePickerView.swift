import SwiftUI

/// Compact KZ / RU / ENG chips (welcome top-trailing, important-info on light card).
struct LanguagePickerView: View {
    enum Style {
        case onDark
        case onLight
    }

    @EnvironmentObject private var language: LanguageStore
    var style: Style = .onDark

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
                        .foregroundStyle(foreground(for: code))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            Capsule(style: .continuous)
                                .fill(background(for: code))
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .accessibilityLabel("Language")
    }

    private func foreground(for code: AppLanguageCode) -> Color {
        let selected = language.code == code
        switch style {
        case .onDark:
            return selected ? AppTheme.authLink : Color.white.opacity(0.78)
        case .onLight:
            return selected ? AppTheme.brandBlue : Color.black.opacity(0.45)
        }
    }

    private func background(for code: AppLanguageCode) -> Color {
        let selected = language.code == code
        switch style {
        case .onDark:
            return selected ? Color.white.opacity(0.16) : Color.clear
        case .onLight:
            return selected ? AppTheme.brandBlue.opacity(0.12) : Color.clear
        }
    }
}
