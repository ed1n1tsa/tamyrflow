import SwiftUI

struct ProfileSetupBackground: View {
    var body: some View {
        GeometryReader { geo in
            Image("ProfileBackground")
                .resizable()
                .scaledToFill()
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
        }
        .ignoresSafeArea()
    }
}

struct ProfileSetupProgress: View {
    let step: Int // 1...5
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                ForEach(1...total, id: \.self) { index in
                    Capsule(style: .continuous)
                        .fill(index <= step ? ProfileTheme.accent : ProfileTheme.accent.opacity(0.22))
                        .frame(height: 4)
                        .shadow(color: index <= step ? ProfileTheme.accent.opacity(0.55) : .clear, radius: 4, y: 0)
                }
            }
            Text(String(format: L10n.ProfileSetup.stepFormat, step, total))
                .font(AppFont.interBold(12))
                .foregroundStyle(ProfileTheme.muted)
        }
    }
}

struct ProfileSetupNavBar: View {
    var backTitle: String
    var nextTitle: String
    var nextEnabled: Bool
    var onBack: () -> Void
    var onNext: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onBack) {
                HStack(spacing: 8) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .bold))
                    Text(backTitle)
                        .font(AppFont.interBold(15))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule(style: .continuous)
                        .strokeBorder(ProfileTheme.accent.opacity(0.85), lineWidth: 1.2)
                )
            }
            .buttonStyle(.plain)

            Button(action: onNext) {
                HStack(spacing: 8) {
                    Text(nextTitle)
                        .font(AppFont.interBold(15))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(
                    Capsule(style: .continuous)
                        .fill(nextEnabled ? ProfileTheme.accent : ProfileTheme.accent.opacity(0.35))
                )
                .shadow(color: nextEnabled ? ProfileTheme.accent.opacity(0.35) : .clear, radius: 10, y: 2)
            }
            .buttonStyle(.plain)
            .disabled(!nextEnabled)
        }
    }
}

struct ProfileWheelPicker: View {
    let values: [Int]
    @Binding var selection: Int
    var unit: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(ProfileTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(ProfileTheme.cardBorder, lineWidth: 1)
                )

            Picker("", selection: $selection) {
                ForEach(values, id: \.self) { value in
                    Text("\(value) \(unit)")
                        .font(AppFont.interBold(22))
                        .foregroundStyle(.white)
                        .tag(value)
                }
            }
            .pickerStyle(.wheel)
            .labelsHidden()
            .frame(height: 220)
        }
        .frame(height: 240)
    }
}
