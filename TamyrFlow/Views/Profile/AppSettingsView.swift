import SwiftUI

/// App + watch preferences in Profile visual language (replaces stub Settings).
struct AppSettingsView: View {
    @EnvironmentObject private var vm: BluetoothViewModel
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss

    @State private var toast: String?

    var body: some View {
        ZStack {
            ProfileSetupBackground()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        sectionTitle(L10n.Settings.languageSection)
                        languageCard

                        sectionTitle(L10n.Settings.devicePrefs)
                        deviceCard

                        sectionTitle(L10n.Settings.timeCard)
                        timeCard
                    }
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 14)
                    .padding(.bottom, 32)
                }
            }

            if let toast {
                VStack {
                    Spacer()
                    Text(toast)
                        .font(AppFont.interBold(13))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(
                            Capsule().fill(Color(red: 0.05, green: 0.18, blue: 0.12).opacity(0.95))
                        )
                        .padding(.bottom, 28)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .id(language.code)
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
            Text(L10n.Settings.title)
                .font(AppFont.interBold(17))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(AppFont.interBold(13))
            .foregroundStyle(ProfileTheme.muted)
            .padding(.top, 4)
    }

    private var languageCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(AppLanguageCode.allCases.enumerated()), id: \.element.id) { index, code in
                Button {
                    language.set(code)
                    flash(L10n.Settings.languageSaved)
                } label: {
                    HStack(spacing: 12) {
                        Text(code.nativeName)
                            .font(AppFont.interBold(15))
                            .foregroundStyle(.white)
                        Text(code.shortLabel)
                            .font(AppFont.interBold(12))
                            .foregroundStyle(ProfileTheme.muted)
                        Spacer()
                        if language.code == code {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(ProfileTheme.accent)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.plain)
                if index < AppLanguageCode.allCases.count - 1 {
                    Rectangle().fill(ProfileTheme.rowDivider).frame(height: 0.5).padding(.leading, 16)
                }
            }
        }
        .profileCard()
    }

    private var deviceCard: some View {
        VStack(spacing: 0) {
            toggleRow(L10n.Settings.metric, systemImage: "ruler", isOn: $vm.useMetric)
            divider
            toggleRow(L10n.Settings.time24, systemImage: "clock", isOn: $vm.use24h)

            Button {
                vm.applyDeviceTogglesToWatch()
                flash(L10n.Settings.togglesApplied)
            } label: {
                Text(L10n.Settings.applyToggles)
                    .font(AppFont.interBold(14))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Capsule().fill(ProfileTheme.accent))
            }
            .buttonStyle(.plain)
            .padding(14)
        }
        .profileCard()
    }

    private var timeCard: some View {
        Button {
            vm.healthService.syncTime()
            flash(L10n.Settings.timeSynced)
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "clock.arrow.2.circlepath")
                    .foregroundStyle(ProfileTheme.accent)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(ProfileTheme.accent.opacity(0.16)))
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.Settings.syncTimeBand)
                        .font(AppFont.interBold(15))
                        .foregroundStyle(.white)
                    Text(L10n.Settings.timeCardSub)
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(ProfileTheme.muted)
            }
            .padding(14)
            .profileCard()
        }
        .buttonStyle(.plain)
    }

    private func toggleRow(_ title: String, systemImage: String, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .foregroundStyle(ProfileTheme.accent)
                    .frame(width: 28)
                Text(title)
                    .font(AppFont.interBold(14))
                    .foregroundStyle(.white)
            }
        }
        .tint(ProfileTheme.accent)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Rectangle().fill(ProfileTheme.rowDivider).frame(height: 0.5).padding(.leading, 56)
    }

    private func flash(_ text: String) {
        withAnimation { toast = text }
        Task {
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            withAnimation { toast = nil }
        }
    }
}
