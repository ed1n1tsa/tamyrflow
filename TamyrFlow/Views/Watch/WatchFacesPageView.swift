import SwiftUI
import VeepooBleSDK

/// Built-in dial style picker for the connected Veepoo band.
struct WatchFacesPageView: View {
    @EnvironmentObject private var vm: BluetoothViewModel
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss

    @State private var styleCount = 0
    @State private var selectedStyle: Int?
    @State private var isLoading = true
    @State private var isApplying = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?

    private var isConnected: Bool {
        vm.bleService.connectionStatus == .connected
            || vm.bleService.connectionStatus == .verified
    }

    var body: some View {
        let _ = language.revision
        ZStack {
            ProfileSetupBackground()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        introCard

                        if !isConnected {
                            infoCard(
                                title: L10n.Watch.facesNeedWatchTitle,
                                body: L10n.Watch.facesNeedWatchBody
                            )
                        } else if isLoading {
                            ProgressView()
                                .tint(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 40)
                        } else if styleCount <= 0 {
                            infoCard(
                                title: L10n.Watch.facesUnsupportedTitle,
                                body: L10n.Watch.facesUnsupportedBody
                            )
                        } else {
                            VStack(spacing: 12) {
                                ForEach(1...styleCount, id: \.self) { style in
                                    faceRow(style: style)
                                }
                            }

                            Text(L10n.Watch.facesHint)
                                .font(AppFont.interBold(12))
                                .foregroundStyle(ProfileTheme.muted)
                                .fixedSize(horizontal: false, vertical: true)
                                .padding(.top, 4)
                        }

                        if let statusMessage {
                            Text(statusMessage)
                                .font(AppFont.interBold(13))
                                .foregroundStyle(ProfileTheme.accent)
                        }
                        if let errorMessage {
                            Text(errorMessage)
                                .font(AppFont.interBold(13))
                                .foregroundStyle(AppTheme.danger)
                        }
                    }
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 14)
                    .padding(.bottom, 32)
                }
            }
        }
        .navigationBarHidden(true)
        .disabled(isApplying)
        .opacity(isApplying ? 0.85 : 1)
        .task { await reload() }
        .onChange(of: isConnected) { _, on in
            if on { Task { await reload() } }
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
            Spacer()
            Text(L10n.Watch.setFaces)
                .font(AppFont.interBold(17))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
    }

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Watch.facesTitle)
                .font(AppFont.interBold(20))
                .foregroundStyle(.white)
            Text(L10n.Watch.facesSubtitle)
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .profileCard()
    }

    private func infoCard(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.interBold(15))
                .foregroundStyle(.white)
            Text(body)
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .profileCard()
    }

    private func faceRow(style: Int) -> some View {
        let selected = selectedStyle == style
        let palette = WatchFaceStyleLook.palette(for: style)

        return Button {
            Task { await apply(style: style) }
        } label: {
            HStack(spacing: 16) {
                WatchFaceStylePreview(style: style, selected: selected)
                    .frame(width: 92, height: 92)

                VStack(alignment: .leading, spacing: 6) {
                    Text(WatchFaceStyleLook.title(for: style))
                        .font(AppFont.interBold(16))
                        .foregroundStyle(.white)

                    Text(WatchFaceStyleLook.subtitle(for: style))
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 6) {
                        Circle()
                            .fill(palette.accent)
                            .frame(width: 8, height: 8)
                        Text(WatchFaceStyleLook.tag(for: style))
                            .font(AppFont.interBold(11))
                            .foregroundStyle(palette.accent.opacity(0.95))
                    }
                    .padding(.top, 2)
                }

                Spacer(minLength: 0)

                VStack(spacing: 8) {
                    if selected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(palette.accent)
                        Text(L10n.Watch.facesActive)
                            .font(AppFont.interBold(11))
                            .foregroundStyle(palette.accent)
                    } else {
                        Image(systemName: "circle")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(ProfileTheme.muted.opacity(0.7))
                        Text(L10n.Watch.facesApply)
                            .font(AppFont.interBold(11))
                            .foregroundStyle(ProfileTheme.muted)
                            .multilineTextAlignment(.center)
                            .frame(width: 72)
                    }
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                palette.cardTop.opacity(selected ? 0.55 : 0.28),
                                Color.black.opacity(selected ? 0.35 : 0.22)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(
                        selected ? palette.accent.opacity(0.9) : ProfileTheme.cardBorder,
                        lineWidth: selected ? 1.6 : 1
                    )
            )
            .shadow(color: selected ? palette.accent.opacity(0.28) : .clear, radius: 14, y: 4)
            .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: selected)
    }

    private func reload() async {
        isLoading = true
        errorMessage = nil
        statusMessage = nil
        defer { isLoading = false }

        guard isConnected else {
            styleCount = 0
            selectedStyle = nil
            return
        }

        styleCount = vm.bleService.builtInDialStyleCount
        if styleCount <= 0 {
            selectedStyle = nil
            return
        }
        selectedStyle = await vm.bleService.readBuiltInDialStyle()
    }

    private func apply(style: Int) async {
        guard !isApplying else { return }
        isApplying = true
        errorMessage = nil
        statusMessage = nil
        defer { isApplying = false }

        let ok = await vm.bleService.setBuiltInDialStyle(style)
        if ok {
            selectedStyle = style
            statusMessage = L10n.Watch.facesApplied
        } else {
            errorMessage = L10n.Watch.facesApplyFailed
        }
    }
}

// MARK: - Style look & preview

private enum WatchFaceStyleLook {
    struct Palette {
        let accent: Color
        let secondary: Color
        let cardTop: Color
    }

    static func palette(for style: Int) -> Palette {
        switch style {
        case 1:
            return Palette(
                accent: Color(red: 1.0, green: 0.62, blue: 0.18),
                secondary: Color(red: 0.35, green: 0.90, blue: 0.45),
                cardTop: Color(red: 0.45, green: 0.22, blue: 0.08)
            )
        case 2:
            return Palette(
                accent: Color(red: 1.0, green: 0.28, blue: 0.38),
                secondary: Color(red: 0.35, green: 0.78, blue: 1.0),
                cardTop: Color(red: 0.42, green: 0.08, blue: 0.16)
            )
        case 3:
            return Palette(
                accent: Color(red: 0.25, green: 0.92, blue: 1.0),
                secondary: Color(red: 0.45, green: 0.70, blue: 1.0),
                cardTop: Color(red: 0.05, green: 0.28, blue: 0.42)
            )
        default:
            return Palette(
                accent: ProfileTheme.accent,
                secondary: Color.cyan,
                cardTop: Color(red: 0.12, green: 0.18, blue: 0.38)
            )
        }
    }

    static func title(for style: Int) -> String {
        switch style {
        case 1: return L10n.Watch.facesStyle1Title
        case 2: return L10n.Watch.facesStyle2Title
        case 3: return L10n.Watch.facesStyle3Title
        default: return String(format: L10n.Watch.facesStyleFormat, style)
        }
    }

    static func subtitle(for style: Int) -> String {
        switch style {
        case 1: return L10n.Watch.facesStyle1Sub
        case 2: return L10n.Watch.facesStyle2Sub
        case 3: return L10n.Watch.facesStyle3Sub
        default: return L10n.Watch.facesStyleGenericSub
        }
    }

    static func tag(for style: Int) -> String {
        switch style {
        case 1: return L10n.Watch.facesStyle1Tag
        case 2: return L10n.Watch.facesStyle2Tag
        case 3: return L10n.Watch.facesStyle3Tag
        default: return L10n.Watch.facesStyleGenericTag
        }
    }
}

private struct WatchFaceStylePreview: View {
    let style: Int
    let selected: Bool

    private var palette: WatchFaceStyleLook.Palette {
        WatchFaceStyleLook.palette(for: style)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black)
            Circle()
                .strokeBorder(
                    AngularGradient(
                        colors: [
                            palette.accent.opacity(selected ? 0.95 : 0.55),
                            palette.secondary.opacity(0.35),
                            palette.accent.opacity(selected ? 0.8 : 0.4),
                            .white.opacity(0.15),
                            palette.accent.opacity(selected ? 0.95 : 0.55)
                        ],
                        center: .center
                    ),
                    lineWidth: selected ? 2.4 : 1.4
                )

            Group {
                switch style {
                case 1: styleOne
                case 2: styleTwo
                case 3: styleThree
                default: styleGeneric
                }
            }
            .padding(10)
        }
        .shadow(color: palette.accent.opacity(selected ? 0.45 : 0.18), radius: selected ? 12 : 6)
    }

    /// Sport dashboard: time + orange streak + bottom gauge.
    private var styleOne: some View {
        ZStack {
            // Warm streak
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.orange.opacity(0.05),
                            Color.orange.opacity(0.85),
                            Color.yellow.opacity(0.7)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 5)
                .offset(x: 14)
                .blur(radius: 0.4)

            VStack(alignment: .leading, spacing: 3) {
                Text("NOV 12")
                    .font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundStyle(.white.opacity(0.7))
                Text("12:54")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .minimumScaleFactor(0.7)
                HStack(spacing: 4) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(palette.secondary)
                    Text("48")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer(minLength: 0)
                ZStack {
                    Capsule()
                        .strokeBorder(
                            AngularGradient(
                                colors: [.green, .yellow, .orange, .red],
                                center: .center,
                                startAngle: .degrees(200),
                                endAngle: .degrees(340)
                            ),
                            lineWidth: 3
                        )
                        .frame(width: 34, height: 14)
                        .rotationEffect(.degrees(180))
                        .offset(y: 2)
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.leading, 4)
        }
    }

    /// Neon vital: heart + dual gauges.
    private var styleTwo: some View {
        ZStack {
            Image(systemName: "heart.fill")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [palette.accent, Color.pink.opacity(0.8)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .shadow(color: palette.accent.opacity(0.7), radius: 6)
                .offset(x: -18, y: 2)

            VStack(spacing: 6) {
                gaugeRing(color: palette.secondary, value: 0.62)
                gaugeRing(color: palette.accent, value: 0.38)
            }
            .offset(x: 2)

            VStack(alignment: .trailing, spacing: 1) {
                Text("12:55")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("THU")
                    .font(.system(size: 7, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
            .padding(.trailing, 2)
            .padding(.top, 2)
        }
    }

    /// Arc reactor cyan minimal.
    private var styleThree: some View {
        HStack(spacing: 6) {
            ZStack {
                ForEach(0..<3, id: \.self) { i in
                    Circle()
                        .strokeBorder(
                            palette.accent.opacity(0.35 + Double(i) * 0.2),
                            style: StrokeStyle(lineWidth: 2, dash: i == 2 ? [3, 2] : [])
                        )
                        .frame(width: CGFloat(18 + i * 10), height: CGFloat(18 + i * 10))
                }
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [.white, palette.accent, palette.accent.opacity(0.1)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 10
                        )
                    )
                    .frame(width: 12, height: 12)
                    .shadow(color: palette.accent.opacity(0.9), radius: 6)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("12:55")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(palette.accent)
                    .shadow(color: palette.accent.opacity(0.6), radius: 4)
                Text("Thu 12")
                    .font(.system(size: 8, weight: .semibold, design: .rounded))
                    .foregroundStyle(palette.accent.opacity(0.75))
            }
        }
    }

    private var styleGeneric: some View {
        VStack(spacing: 6) {
            Image(systemName: "applewatch")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(palette.accent)
            Text(String(format: L10n.Watch.facesStyleFormat, style))
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundStyle(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func gaugeRing(color: Color, value: CGFloat) -> some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 2.5)
            Circle()
                .trim(from: 0, to: value)
                .stroke(color, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 22, height: 22)
        .shadow(color: color.opacity(0.45), radius: 3)
    }
}
