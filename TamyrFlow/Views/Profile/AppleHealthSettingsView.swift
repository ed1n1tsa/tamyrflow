import HealthKit
import SwiftUI
import UIKit

/// Dedicated Apple Health (HealthKit) screen — required for App Store Guideline 2.5.1 transparency.
struct AppleHealthSettingsView: View {
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL

    @State private var isRequesting = false
    @State private var toast: String?
    @State private var availabilityLabel = ""
    @State private var heartRateShareStatus = ""

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
                        heroCard
                        sectionTitle(L10n.AppleHealth.dataSection)
                        dataTypesCard
                        sectionTitle(L10n.AppleHealth.manageSection)
                        actionsCard
                        disclaimerCard
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
        .task { refreshStatus() }
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
            Text(L10n.AppleHealth.title)
                .font(AppFont.interBold(17))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
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

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(ProfileTheme.accent)
                    .frame(width: 52, height: 52)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(ProfileTheme.accent.opacity(0.18)))

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.AppleHealth.brandTitle)
                        .font(AppFont.interBold(18))
                        .foregroundStyle(.white)
                    Text(L10n.AppleHealth.brandSubtitle)
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(L10n.AppleHealth.intro)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.88))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            Label {
                Text(availabilityLabel)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(.white)
            } icon: {
                Image(systemName: HKHealthStore.isHealthDataAvailable() ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundStyle(HKHealthStore.isHealthDataAvailable() ? ProfileTheme.accent : AppTheme.danger)
            }
        }
        .padding(16)
        .profileCard()
    }

    private var dataTypesCard: some View {
        VStack(spacing: 0) {
            dataRow(
                title: L10n.AppleHealth.heartRate,
                detail: L10n.AppleHealth.heartRateDetail,
                systemImage: "heart.fill",
                status: heartRateShareStatus
            )
            divider
            dataRow(
                title: L10n.AppleHealth.steps,
                detail: L10n.AppleHealth.stepsDetail,
                systemImage: "figure.walk",
                status: L10n.AppleHealth.readOnly
            )
            divider
            dataRow(
                title: L10n.AppleHealth.sleep,
                detail: L10n.AppleHealth.sleepDetail,
                systemImage: "moon.zzz.fill",
                status: L10n.AppleHealth.readOnly
            )
        }
        .profileCard()
    }

    private var actionsCard: some View {
        VStack(spacing: 10) {
            Button {
                Task { await connectAppleHealth() }
            } label: {
                HStack {
                    if isRequesting {
                        ProgressView().tint(.white)
                    }
                    Text(L10n.AppleHealth.connectButton)
                        .font(AppFont.interBold(15))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Capsule().fill(ProfileTheme.accent))
            }
            .buttonStyle(.plain)
            .disabled(isRequesting || !HKHealthStore.isHealthDataAvailable())

            Button {
                openSystemHealthSettings()
            } label: {
                Text(L10n.AppleHealth.openSettingsButton)
                    .font(AppFont.interBold(14))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        Capsule()
                            .strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
                            .background(Capsule().fill(ProfileTheme.cardFill))
                    )
            }
            .buttonStyle(.plain)

            Text(L10n.AppleHealth.manageHint)
                .font(AppFont.interBold(12))
                .foregroundStyle(ProfileTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .profileCard()
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.AppleHealth.disclaimerTitle)
                .font(AppFont.interBold(14))
                .foregroundStyle(.white)
            Text(L10n.AppleHealth.disclaimerBody)
                .font(.system(size: 13, weight: .regular))
                .foregroundStyle(Color.white.opacity(0.82))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .profileCard()
    }

    private func dataRow(title: String, detail: String, systemImage: String, status: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(ProfileTheme.accent)
                .frame(width: 28)
                .padding(.top, 2)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(AppFont.interBold(15))
                    .foregroundStyle(.white)
                Text(detail)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            Text(status)
                .font(AppFont.interBold(11))
                .foregroundStyle(ProfileTheme.accent)
                .multilineTextAlignment(.trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Rectangle().fill(ProfileTheme.rowDivider).frame(height: 0.5).padding(.leading, 56)
    }

    private func refreshStatus() {
        if HKHealthStore.isHealthDataAvailable() {
            availabilityLabel = L10n.AppleHealth.available
        } else {
            availabilityLabel = L10n.AppleHealth.unavailable
        }
        heartRateShareStatus = HealthKitWellnessService.heartRateShareStatusLabel()
    }

    private func connectAppleHealth() async {
        isRequesting = true
        defer { isRequesting = false }
        let ok = await HealthKitWellnessService.requestAllAppAccess()
        refreshStatus()
        flash(ok ? L10n.AppleHealth.connectDone : L10n.AppleHealth.connectFailed)
    }

    private func openSystemHealthSettings() {
        // Prefer Health app sources page when available; fall back to app settings.
        if let healthURL = URL(string: "x-apple-health://"),
           UIApplication.shared.canOpenURL(healthURL) {
            openURL(healthURL)
            return
        }
        if let settings = URL(string: UIApplication.openSettingsURLString) {
            openURL(settings)
        }
    }

    private func flash(_ text: String) {
        withAnimation { toast = text }
        Task {
            try? await Task.sleep(nanoseconds: 1_800_000_000)
            withAnimation { toast = nil }
        }
    }
}
