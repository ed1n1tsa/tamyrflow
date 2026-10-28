import SwiftUI

enum PulseSheetKind: Identifiable, Equatable {
    case aboutPulse
    case howItWorks
    case updateProblems
    case zonesInfo
    case measurementDetail(PulseMeasurement)
    case noNewData
    case syncError(String)

    var id: String {
        switch self {
        case .aboutPulse: return "about"
        case .howItWorks: return "how"
        case .updateProblems: return "problems"
        case .zonesInfo: return "zones"
        case .measurementDetail(let m): return "m-\(m.id)"
        case .noNewData: return "nonew"
        case .syncError: return "err"
        }
    }
}

struct PulseInfoSheet: View {
    let kind: PulseSheetKind
    var onConnectWatch: (() -> Void)?
    var onRetry: (() -> Void)?
    var onSupport: (() -> Void)?
    var onDismiss: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    content
                    actions
                }
                .padding(20)
            }
            .background(ProfileTheme.page.ignoresSafeArea())
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.Pulse.close) { onDismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .preferredColorScheme(.dark)
    }

    private var title: String {
        switch kind {
        case .aboutPulse: return L10n.Pulse.sheetAboutTitle
        case .howItWorks: return L10n.Pulse.sheetHowTitle
        case .updateProblems: return L10n.Pulse.sheetProblemsTitle
        case .zonesInfo: return L10n.Pulse.sheetZonesTitle
        case .measurementDetail: return L10n.Pulse.sheetDetailTitle
        case .noNewData: return L10n.Pulse.sheetNoNewTitle
        case .syncError: return L10n.Pulse.sheetErrorTitle
        }
    }

    @ViewBuilder
    private var content: some View {
        switch kind {
        case .aboutPulse:
            sheetText(L10n.Pulse.sheetAboutBody)
        case .howItWorks:
            sheetText(L10n.Pulse.sheetHowBody)
        case .updateProblems:
            sheetText(L10n.Pulse.sheetProblemsBody)
        case .zonesInfo:
            sheetText(L10n.Pulse.sheetZonesBody)
        case .noNewData:
            VStack(spacing: 14) {
                Image(systemName: "heart")
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(ProfileTheme.accent)
                sheetText(L10n.Pulse.sheetNoNewBody)
            }
            .frame(maxWidth: .infinity)
        case .syncError(let message):
            VStack(alignment: .leading, spacing: 12) {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(AppTheme.danger)
                sheetText(L10n.Pulse.sheetErrorBody)
                if !message.isEmpty {
                    Text(message)
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)
                }
            }
        case .measurementDetail(let m):
            VStack(alignment: .leading, spacing: 12) {
                detailRow(L10n.Pulse.detailPulse, PulseFormatters.bpmWithUnit(m.value))
                detailRow(L10n.Pulse.detailWhen, PulseFormatters.shortDateTime(m.recordedAt))
                detailRow(L10n.Pulse.detailSource, PulseFormatters.sourceTitle(m.source))
                if let type = m.recordType, !type.isEmpty {
                    detailRow(L10n.Pulse.detailType, type)
                }
                if let device = m.deviceLabel, !device.isEmpty {
                    detailRow(L10n.Pulse.detailDevice, device)
                }
            }
        }
    }

    @ViewBuilder
    private var actions: some View {
        switch kind {
        case .aboutPulse, .zonesInfo, .measurementDetail, .noNewData:
            primaryButton(L10n.Pulse.gotIt, action: onDismiss)
        case .howItWorks:
            primaryButton(L10n.Pulse.connectWatch) {
                onConnectWatch?()
                onDismiss()
            }
            secondaryLink(L10n.Pulse.gotIt, action: onDismiss)
        case .updateProblems:
            primaryButton(L10n.Pulse.retry) {
                onRetry?()
                onDismiss()
            }
            secondaryLink(L10n.Pulse.support) {
                onSupport?()
                onDismiss()
            }
        case .syncError:
            primaryButton(L10n.Pulse.retry) {
                onRetry?()
                onDismiss()
            }
            secondaryLink(L10n.Pulse.support) {
                onSupport?()
                onDismiss()
            }
        }
    }

    private func sheetText(_ text: String) -> some View {
        Text(text)
            .font(AppFont.interBold(14))
            .foregroundStyle(Color.white.opacity(0.82))
            .lineSpacing(5)
            .fixedSize(horizontal: false, vertical: true)
    }

    private func detailRow(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFont.interBold(12))
                .foregroundStyle(ProfileTheme.muted)
            Text(value)
                .font(AppFont.interBold(16))
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(ProfileTheme.cardFill)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
                )
        )
    }

    private func primaryButton(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.interBold(15))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    Capsule(style: .continuous)
                        .fill(ProfileTheme.accent)
                        .shadow(color: ProfileTheme.accent.opacity(0.4), radius: 10, y: 3)
                )
        }
        .buttonStyle(.plain)
        .padding(.top, 8)
    }

    private func secondaryLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(AppFont.interBold(14))
                .foregroundStyle(ProfileTheme.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}
