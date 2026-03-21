import SwiftUI

struct TFScreenBackground: View {
    var body: some View {
        ZStack {
            AppTheme.backgroundGradient
                .ignoresSafeArea()
            AppTheme.meshGlow
                .ignoresSafeArea()
        }
    }
}

struct TFCard<Content: View>: View {
    var title: String?
    var subtitle: String?
    @ViewBuilder var content: () -> Content

    init(title: String? = nil, subtitle: String? = nil, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let title {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.white)
                    if let subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.55))
                    }
                }
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(AppTheme.cardBackground)
                .background {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                }
        }
    }
}

struct TFPrimaryButton: View {
    let title: String
    let systemImage: String?
    let action: () -> Void

    init(_ title: String, systemImage: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                LinearGradient(
                    colors: [AppTheme.accent, AppTheme.accent.opacity(0.75)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }
            .foregroundStyle(Color.black.opacity(0.85))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

struct TFSecondaryButton: View {
    let title: String
    let action: () -> Void

    init(_ title: String, action: @escaping () -> Void) {
        self.title = title
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.medium)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.1))
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(AppTheme.cardBorder, lineWidth: 1)
                }
        }
        .buttonStyle(.plain)
    }
}

struct TFMetricBadge: View {
    let value: String
    let unit: String
    let label: String
    var tint: Color = AppTheme.accent

    var body: some View {
        VStack(spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                Text(unit)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.6))
            }
            .foregroundStyle(tint)
            Text(label)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

extension View {
    func tfNavigationChrome() -> some View {
        toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
    }
}
