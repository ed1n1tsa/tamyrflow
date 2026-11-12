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
                            LazyVGrid(
                                columns: [GridItem(.flexible()), GridItem(.flexible())],
                                spacing: 12
                            ) {
                                ForEach(1...styleCount, id: \.self) { style in
                                    faceTile(style: style)
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

    private func faceTile(style: Int) -> some View {
        let selected = selectedStyle == style
        return Button {
            Task { await apply(style: style) }
        } label: {
            VStack(spacing: 10) {
                ZStack {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    ProfileTheme.accent.opacity(selected ? 0.45 : 0.22),
                                    Color.cyan.opacity(selected ? 0.28 : 0.10)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 110)
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .strokeBorder(
                                    selected ? ProfileTheme.accent : ProfileTheme.cardBorder,
                                    lineWidth: selected ? 2 : 1
                                )
                        )

                    VStack(spacing: 6) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundStyle(selected ? .white : ProfileTheme.accent)
                        Text(String(format: L10n.Watch.facesStyleFormat, style))
                            .font(AppFont.interBold(13))
                            .foregroundStyle(.white)
                    }
                }

                if selected {
                    Label(L10n.Watch.facesActive, systemImage: "checkmark.circle.fill")
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.accent)
                } else {
                    Text(L10n.Watch.facesApply)
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .profileCard()
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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
