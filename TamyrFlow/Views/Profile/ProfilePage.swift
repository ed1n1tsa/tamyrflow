import Auth
import SwiftUI
import VeepooBleSDK

struct ProfilePage: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var vm: BluetoothViewModel
    @EnvironmentObject private var language: LanguageStore

    @State private var showLogoutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var stubAlert: String?
    @State private var showEditProfile = false

    private var profile: UserProfile? { auth.profile }

    var body: some View {
        NavigationStack {
            ZStack {
                ProfileSetupBackground()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        header
                        userCard
                        goalsCard
                        watchCard
                        menuGroup(items: personalMenu)
                        menuGroup(items: settingsMenu)
                        menuGroup(items: legalMenu)

                        accountButton(
                            title: L10n.Profile.logout,
                            systemImage: "rectangle.portrait.and.arrow.right",
                            isDestructive: true
                        ) {
                            showLogoutConfirm = true
                        }
                        .padding(.top, 4)

                        accountButton(
                            title: L10n.Profile.deleteAccount,
                            systemImage: "trash.fill",
                            isDestructive: true
                        ) {
                            showDeleteConfirm = true
                        }
                    }
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 10)
                    .padding(.bottom, 28)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: $showEditProfile) {
                EditProfileView()
            }
        }
        .id(language.code)
        .alert(L10n.Profile.logoutConfirmTitle, isPresented: $showLogoutConfirm) {
            Button(L10n.Profile.cancel, role: .cancel) {}
            Button(L10n.Profile.logout, role: .destructive) {
                Task { await auth.signOut() }
            }
        } message: {
            Text(L10n.Profile.logoutConfirmBody)
        }
        .alert(L10n.Profile.deleteConfirmTitle, isPresented: $showDeleteConfirm) {
            Button(L10n.Profile.cancel, role: .cancel) {}
            Button(L10n.Profile.deleteConfirmAction, role: .destructive) {
                Task {
                    do {
                        try await auth.deleteAccount()
                    } catch {
                        auth.lastError = error.localizedDescription
                        stubAlert = error.localizedDescription
                    }
                }
            }
        } message: {
            Text(L10n.Profile.deleteConfirmBody)
        }
        .alert(L10n.Profile.stubTitle, isPresented: Binding(
            get: { stubAlert != nil },
            set: { if !$0 { stubAlert = nil } }
        )) {
            Button(L10n.ProfileSetup.sheetDone, role: .cancel) {}
        } message: {
            Text(stubAlert ?? "")
        }
        .task {
            await auth.refreshProfile()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 8) {
                    BrandLogoMark()
                    Text("TAMYR FLOW")
                        .font(AppFont.interBold(15))
                        .tracking(1)
                        .foregroundStyle(.white)
                }
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(8)
                    Circle()
                        .fill(AppTheme.danger)
                        .frame(width: 8, height: 8)
                        .offset(x: -4, y: 4)
                }
            }

            Text(L10n.Profile.title)
                .font(AppFont.interBold(30))
                .foregroundStyle(.white)
            Text(L10n.Profile.subtitle)
                .font(AppFont.interBold(14))
                .foregroundStyle(ProfileTheme.muted)
        }
        .padding(.bottom, 6)
    }

    // MARK: - Cards

    private var userCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .center, spacing: 12) {
                ProfileAvatarView(urlString: profile?.avatarUrl, size: 60)

                VStack(alignment: .leading, spacing: 5) {
                    Text(profile?.displayName ?? "—")
                        .font(AppFont.interBold(20))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Text(profile?.email ?? auth.session?.user.email ?? "—")
                        .font(AppFont.interBold(13))
                        .foregroundStyle(ProfileTheme.muted)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Spacer(minLength: 8)
                Button {
                    showEditProfile = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
                                .background(Circle().fill(ProfileTheme.accent.opacity(0.12)))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.Profile.edit)
            }

            metricsRow
        }
        .padding(16)
        .profileCard()
    }

    private var metricsRow: some View {
        let items: [(String, String, String)] = [
            ("person.fill", L10n.Profile.gender, genderLabel),
            ("calendar", L10n.Profile.age, ageLabel),
            ("ruler", L10n.Profile.height, heightLabel),
            ("scalemass.fill", L10n.Profile.weight, weightLabel)
        ]

        return HStack(alignment: .top, spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                VStack(spacing: 6) {
                    Image(systemName: item.0)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ProfileTheme.accent)
                        .frame(height: 18)
                    Text(item.1)
                        .font(AppFont.interBold(11))
                        .foregroundStyle(ProfileTheme.muted)
                        .frame(height: 14)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                    Text(item.2)
                        .font(AppFont.interBold(13))
                        .foregroundStyle(.white)
                        .frame(height: 16)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 2)
    }

    private var goalsCard: some View {
        Button {
            stubAlert = L10n.Profile.stubBody
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "target")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(ProfileTheme.accent)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(ProfileTheme.accent.opacity(0.18)))

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Profile.goalsTitle)
                        .font(AppFont.interBold(15))
                        .foregroundStyle(.white)
                    Text(L10n.Profile.goalsSubMock)
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.1))
                            Capsule()
                                .fill(ProfileTheme.accent)
                                .frame(width: geo.size.width * 0.6)
                        }
                    }
                    .frame(height: 7)
                }

                Text("60%")
                    .font(AppFont.interBold(14))
                    .foregroundStyle(ProfileTheme.accent)
                Image(systemName: "chevron.right")
                    .foregroundStyle(ProfileTheme.muted)
            }
            .padding(16)
            .profileCard()
        }
        .buttonStyle(.plain)
    }

    private var watchCard: some View {
        let connected = vm.bleService.connectionStatus == .connected
            || vm.bleService.connectionStatus == .verified
        let battery = vm.bleService.batteryInfo.map(\.battery)

        return Button {
            stubAlert = L10n.Profile.stubBody
        } label: {
            HStack(spacing: 14) {
                Image("ProfileWatch")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 68, height: 76)

                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.Profile.myWatch)
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)
                    Text(vm.bleService.connectedDevice?.deviceName ?? "SyncWatch Pro")
                        .font(AppFont.interBold(16))
                        .foregroundStyle(.white)

                    HStack(spacing: 10) {
                        HStack(spacing: 5) {
                            Circle()
                                .fill(connected ? ProfileTheme.connected : AppTheme.danger)
                                .frame(width: 8, height: 8)
                            Text(connected ? L10n.Profile.connected : L10n.Profile.disconnected)
                                .font(AppFont.interBold(12))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                        if let battery {
                            Label("\(battery)%", systemImage: "battery.75")
                                .font(AppFont.interBold(12))
                                .foregroundStyle(.white.opacity(0.85))
                        }
                    }

                    Label(L10n.Profile.lastSyncMock, systemImage: "arrow.triangle.2.circlepath")
                        .font(AppFont.interBold(11))
                        .foregroundStyle(ProfileTheme.accentSoft)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(ProfileTheme.muted)
            }
            .padding(16)
            .profileCard()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Menus

    private struct MenuItem: Identifiable {
        let id = UUID()
        let title: String
        let subtitle: String
        let systemImage: String
    }

    private var personalMenu: [MenuItem] {
        [
            .init(title: L10n.Profile.menuPersonal, subtitle: L10n.Profile.menuPersonalSub, systemImage: "person.text.rectangle"),
            .init(title: L10n.Profile.menuMetrics, subtitle: L10n.Profile.menuMetricsSub, systemImage: "chart.xyaxis.line"),
            .init(title: L10n.Profile.menuGoals, subtitle: L10n.Profile.menuGoalsSub, systemImage: "flag.fill")
        ]
    }

    private var settingsMenu: [MenuItem] {
        [
            .init(title: L10n.Profile.menuSettings, subtitle: L10n.Profile.menuSettingsSub, systemImage: "gearshape.fill"),
            .init(title: L10n.Profile.menuPrivacy, subtitle: L10n.Profile.menuPrivacySub, systemImage: "lock.shield.fill"),
            .init(title: L10n.Profile.menuSupport, subtitle: L10n.Profile.menuSupportSub, systemImage: "questionmark.circle.fill")
        ]
    }

    private var legalMenu: [MenuItem] {
        [
            .init(title: L10n.Profile.menuTerms, subtitle: L10n.Profile.menuTermsSub, systemImage: "doc.text.fill"),
            .init(title: L10n.Profile.menuPolicy, subtitle: L10n.Profile.menuPolicySub, systemImage: "hand.raised.fill"),
            .init(title: L10n.Profile.menuAbout, subtitle: L10n.Profile.menuAboutSub, systemImage: "info.circle.fill")
        ]
    }

    private func menuGroup(items: [MenuItem]) -> some View {
        VStack(spacing: 0) {
            ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
                Button {
                    stubAlert = L10n.Profile.stubBody
                } label: {
                    HStack(spacing: 14) {
                        Image(systemName: item.systemImage)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(ProfileTheme.accent)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(ProfileTheme.accent.opacity(0.16)))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(AppFont.interBold(15))
                                .foregroundStyle(.white)
                            Text(item.subtitle)
                                .font(AppFont.interBold(12))
                                .foregroundStyle(ProfileTheme.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(ProfileTheme.muted)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 13)
                }
                .buttonStyle(.plain)

                if index < items.count - 1 {
                    Rectangle()
                        .fill(ProfileTheme.rowDivider)
                        .frame(height: 0.5)
                        .padding(.leading, 64)
                }
            }
        }
        .profileCard()
    }

    private func accountButton(title: String, systemImage: String, isDestructive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(AppFont.interBold(15))
            .foregroundStyle(isDestructive ? AppTheme.danger : .white)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                Capsule(style: .continuous)
                    .fill(isDestructive ? ProfileTheme.dangerFill : ProfileTheme.cardFill)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(isDestructive ? ProfileTheme.dangerBorder : ProfileTheme.cardBorder, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .disabled(auth.isBusy)
    }

    // MARK: - Labels

    private var genderLabel: String {
        switch profile?.gender {
        case .male: return L10n.ProfileSetup.genderMale
        case .female: return L10n.ProfileSetup.genderFemale
        case .unspecified: return L10n.Profile.genderUnspecifiedShort
        case .none: return "—"
        }
    }

    private var ageLabel: String {
        guard let age = profile?.age else { return "—" }
        return String(format: L10n.ProfileSetup.ageYearsFormat, age)
    }

    private var heightLabel: String {
        guard let h = profile?.heightCm else { return "—" }
        return "\(h) \(L10n.ProfileSetup.cmUnit)"
    }

    private var weightLabel: String {
        guard let w = profile?.weightKg else { return "—" }
        if w.rounded() == w {
            return "\(Int(w)) \(L10n.ProfileSetup.kgUnit)"
        }
        return String(format: "%.1f %@", w, L10n.ProfileSetup.kgUnit)
    }
}

private extension View {
    func profileCard() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                    .fill(ProfileTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                            .stroke(ProfileTheme.cardBorder, lineWidth: 1)
                    )
            )
    }
}
