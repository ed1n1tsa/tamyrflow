import SwiftUI

/// Показатель «Пульс» — connected / disconnected / sync states from TamyrFlow mock.
struct PulsePageView: View {
    @EnvironmentObject private var vm: BluetoothViewModel
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var service: PulseService
    @State private var selectedPoint: PulseChartPoint?
    @State private var sheet: PulseSheetKind?
    @State private var showFullscreenChart = false
    @State private var showHistory = false
    @State private var showConnectWatch = false
    @State private var showAboutSupport = false
    @State private var toast: String?

    init(auth: AuthService, health: VeepooHealthService, ble: BleService) {
        _service = StateObject(wrappedValue: PulseService(auth: auth, health: health, ble: ble))
    }

    var body: some View {
        ZStack {
            GoalsBackgroundView()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        periodPills
                        lastMeasurementCard
                        averageCard
                        dynamicsCard
                        zonesCard
                        if service.isWatchConnected || service.lastMeasurement != nil {
                            recentCard
                            disclaimerCard
                        } else {
                            connectCTACard
                        }
                    }
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 12)
                    .padding(.bottom, 36)
                }
            }

            if case .loading = service.syncState {
                syncOverlay
            }

            if let toast {
                VStack {
                    Spacer()
                    HStack(spacing: 10) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(ProfileTheme.connected)
                        Text(toast)
                            .font(AppFont.interBold(13))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer()
                        Button {
                            self.toast = nil
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(ProfileTheme.muted)
                        }
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(red: 0.05, green: 0.18, blue: 0.12).opacity(0.95))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .strokeBorder(ProfileTheme.connected.opacity(0.45), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .id(language.code)
        .task {
            await service.refresh()
        }
        .onChange(of: service.syncState) { _, state in
            handleSyncState(state)
        }
        .sheet(item: $sheet) { kind in
            PulseInfoSheet(
                kind: kind,
                onConnectWatch: { showConnectWatch = true },
                onRetry: { Task { await service.syncAvailableSources() } },
                onSupport: { openSupport() },
                onDismiss: { sheet = nil }
            )
        }
        .fullScreenCover(isPresented: $showFullscreenChart) {
            PulseFullscreenChartView(service: service)
        }
        .navigationDestination(isPresented: $showHistory) {
            PulseHistoryView(service: service)
        }
        .navigationDestination(isPresented: $showConnectWatch) {
            MyWatchPage()
        }
        .navigationDestination(isPresented: $showAboutSupport) {
            AboutAppView()
        }
    }

    // MARK: - Top

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
            Text(L10n.Pulse.title)
                .font(AppFont.interBold(17))
                .foregroundStyle(.white)
            Spacer()

            Button { sheet = .aboutPulse } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)
        }
    }

    private var periodPills: some View {
        HStack(spacing: 8) {
            ForEach(PulsePeriod.allCases) { period in
                let selected = service.period == period
                Button {
                    Task { await service.setPeriod(period) }
                } label: {
                    Text(L10n.Pulse.periodLabel(period))
                        .font(AppFont.interBold(14))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                Color(red: 0.22, green: 0.48, blue: 1.0),
                                                ProfileTheme.accent
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: ProfileTheme.accent.opacity(0.4), radius: 8, y: 2)
                            } else {
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(ProfileTheme.cardFill)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
                                    )
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Cards

    private var lastMeasurementCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image("PulseHeroHeart")
                .resizable()
                .scaledToFit()
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Pulse.lastMeasurement)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.muted)

                if let last = service.lastMeasurement {
                    Text(PulseFormatters.bpmWithUnit(last.value))
                        .font(AppFont.interBold(26))
                        .foregroundStyle(.white)
                    Text(PulseFormatters.relativeDateTime(last.recordedAt))
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)
                    Text("\(L10n.Pulse.sourceLabel): \(PulseFormatters.sourceTitle(last.source))")
                        .font(AppFont.interBold(11))
                        .foregroundStyle(ProfileTheme.muted.opacity(0.9))
                } else {
                    Text(L10n.Pulse.noData)
                        .font(AppFont.interBold(22))
                        .foregroundStyle(.white)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 8) {
                if service.isWatchConnected {
                    HStack(spacing: 6) {
                        Circle().fill(ProfileTheme.connected).frame(width: 7, height: 7)
                        Text(L10n.Pulse.watchConnected)
                            .font(AppFont.interBold(11))
                            .foregroundStyle(.white)
                    }
                    Image("PulseWatchConnected")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                    Text(L10n.Pulse.newDataAvailable)
                        .font(AppFont.interBold(10))
                        .foregroundStyle(ProfileTheme.muted)
                        .multilineTextAlignment(.trailing)
                    Button {
                        Task { await service.syncAvailableSources() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 11, weight: .bold))
                            Text(L10n.Pulse.refreshData)
                                .font(AppFont.interBold(11))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Capsule().fill(ProfileTheme.accent))
                    }
                    .buttonStyle(.plain)
                } else {
                    Image("PulseWatchDisconnected")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 48, height: 48)
                    Text(L10n.Pulse.watchDisconnected)
                        .font(AppFont.interBold(11))
                        .foregroundStyle(ProfileTheme.muted)
                        .multilineTextAlignment(.trailing)
                    Button { showConnectWatch = true } label: {
                        Text(L10n.Pulse.connectWatch)
                            .font(AppFont.interBold(11))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 8)
                            .background(Capsule().fill(ProfileTheme.accent))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(width: 118, alignment: .trailing)
        }
        .padding(16)
        .pulseCardBackground()
    }

    private var averageCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color(red: 1, green: 0.35, blue: 0.48))
                .frame(width: 40, height: 40)
                .background(Circle().fill(Color(red: 1, green: 0.35, blue: 0.48).opacity(0.18)))

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Pulse.averageTitle)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.muted)
                Text(PulseFormatters.bpmWithUnit(service.stats.average))
                    .font(AppFont.interBold(22))
                    .foregroundStyle(.white)
                if let trend = PulseFormatters.trendText(service.stats.trendPercent, period: service.period) {
                    Text(trend)
                        .font(AppFont.interBold(11))
                        .foregroundStyle(ProfileTheme.connected)
                }
            }
            Spacer()
        }
        .padding(16)
        .pulseCardBackground()
    }

    private var dynamicsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Pulse.dynamicsTitle)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                Spacer()
                Button { showFullscreenChart = true } label: {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ProfileTheme.muted)
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.plain)
            }

            PulseChartView(
                points: service.chartPoints,
                period: service.period,
                selected: $selectedPoint,
                emptyMessage: L10n.Pulse.noData,
                emptySub: service.isWatchConnected ? L10n.Pulse.chartEmptySubConnected : L10n.Pulse.chartEmptySub
            )

            HStack(spacing: 10) {
                minMaxTile(
                    title: L10n.Pulse.minimum,
                    value: service.stats.minimum,
                    at: service.stats.minimumAt
                )
                minMaxTile(
                    title: L10n.Pulse.maximum,
                    value: service.stats.maximum,
                    at: service.stats.maximumAt
                )
            }
        }
        .padding(16)
        .pulseCardBackground()
    }

    private func minMaxTile(title: String, value: Double?, at: Date?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.interBold(12))
                .foregroundStyle(ProfileTheme.muted)
            Text(PulseFormatters.bpmWithUnit(value))
                .font(AppFont.interBold(16))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            if let at {
                Text(PulseFormatters.shortDateTime(at))
                    .font(AppFont.interBold(11))
                    .foregroundStyle(ProfileTheme.muted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.black.opacity(0.22))
        )
    }

    private var zonesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Pulse.zonesTitle)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                Button { sheet = .zonesInfo } label: {
                    Image(systemName: "info.circle")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(ProfileTheme.muted)
                }
                .buttonStyle(.plain)
                Spacer()
            }

            // v1: no reliable zone duration from SDK/samples → insufficient data.
            Text(L10n.Pulse.zonesInsufficient)
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.muted)
                .padding(.bottom, 4)

            ForEach(PulseZoneRow.all) { zone in
                HStack(spacing: 10) {
                    Circle().fill(zone.color).frame(width: 8, height: 8)
                    Text(zone.title)
                        .font(AppFont.interBold(13))
                        .foregroundStyle(.white)
                        .frame(width: 72, alignment: .leading)
                    GeometryReader { geo in
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .overlay(alignment: .leading) {
                                Capsule()
                                    .fill(zone.color.opacity(0.35))
                                    .frame(width: 0)
                            }
                    }
                    .frame(height: 8)
                    Text("—%")
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)
                        .frame(width: 36, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .pulseCardBackground()
    }

    private var recentCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Pulse.recentTitle)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                Spacer()
                Button { showHistory = true } label: {
                    HStack(spacing: 4) {
                        Text(L10n.Pulse.seeAll)
                            .font(AppFont.interBold(13))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(ProfileTheme.accent)
                }
                .buttonStyle(.plain)
            }

            if service.recent.isEmpty {
                Text(L10n.Pulse.noData)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.muted)
            } else {
                ForEach(service.recent) { item in
                    Button { sheet = .measurementDetail(item) } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "heart.fill")
                                .foregroundStyle(Color(red: 1, green: 0.35, blue: 0.48))
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Color(red: 1, green: 0.35, blue: 0.48).opacity(0.16)))
                            VStack(alignment: .leading, spacing: 3) {
                                Text(PulseFormatters.bpmWithUnit(item.value))
                                    .font(AppFont.interBold(15))
                                    .foregroundStyle(.white)
                                Text("\(PulseFormatters.shortDateTime(item.recordedAt)) · \(PulseFormatters.sourceTitle(item.source))")
                                    .font(AppFont.interBold(11))
                                    .foregroundStyle(ProfileTheme.muted)
                                    .lineLimit(1)
                            }
                            Spacer()
                            sourceBadge(item.source)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(ProfileTheme.muted)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .pulseCardBackground()
    }

    @ViewBuilder
    private func sourceBadge(_ source: PulseSource) -> some View {
        switch source {
        case .appleHealth:
            Image("SourceAppleHealth")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
        case .device:
            Image("PulseWatchConnected")
                .resizable()
                .scaledToFit()
                .frame(width: 28, height: 28)
        case .manual:
            EmptyView()
        }
    }

    private var disclaimerCard: some View {
        Button { sheet = .aboutPulse } label: {
            HStack(alignment: .top, spacing: 12) {
                Image("PulseWatchConnected")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                Text(L10n.Pulse.disclaimer)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(Color.white.opacity(0.78))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ProfileTheme.muted)
                    .padding(.top, 4)
            }
            .padding(16)
            .pulseCardBackground()
        }
        .buttonStyle(.plain)
    }

    private var connectCTACard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image("PulseWatchDisconnected")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 6) {
                    Text(L10n.Pulse.connectCTATitle)
                        .font(AppFont.interBold(15))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(L10n.Pulse.connectCTABody)
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Button { showConnectWatch = true } label: {
                Text(L10n.Pulse.connectWatch)
                    .font(AppFont.interBold(15))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(ProfileTheme.accent))
            }
            .buttonStyle(.plain)

            Button { sheet = .howItWorks } label: {
                Text(L10n.Pulse.howItWorks)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.accent)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .pulseCardBackground()
    }

    private var syncOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(ProfileTheme.accent.opacity(0.25), lineWidth: 5)
                        .frame(width: 72, height: 72)
                    ProgressView()
                        .tint(ProfileTheme.accent)
                        .scaleEffect(1.3)
                    Image(systemName: "heart.fill")
                        .foregroundStyle(Color(red: 1, green: 0.35, blue: 0.48))
                }
                Text(L10n.Pulse.syncingTitle)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                Text(L10n.Pulse.syncingBody)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(red: 0.04, green: 0.1, blue: 0.2).opacity(0.96))
            )
            .padding(.horizontal, 36)
        }
    }

    // MARK: - Actions

    private func handleSyncState(_ state: PulseSyncState) {
        switch state {
        case .success:
            withAnimation { toast = L10n.Pulse.toastSuccess }
        case .noNewData:
            sheet = .noNewData
        case .noSource:
            sheet = .howItWorks
        case .error(let message):
            sheet = .syncError(message)
        case .idle, .loading:
            break
        }
    }

    private func openSupport() {
        // Prefer About page (contact section → mailto). Fallback: mailto directly.
        showAboutSupport = true
    }
}

// MARK: - Zone stub rows (labels only for v1)

private struct PulseZoneRow: Identifiable {
    let id: String
    let title: String
    let color: Color

    static var all: [PulseZoneRow] {
        [
            .init(id: "rest", title: L10n.Pulse.zoneRest, color: Color(red: 0.25, green: 0.55, blue: 1)),
            .init(id: "light", title: L10n.Pulse.zoneLight, color: Color(red: 0.25, green: 0.85, blue: 0.55)),
            .init(id: "mid", title: L10n.Pulse.zoneMid, color: Color(red: 1.0, green: 0.7, blue: 0.25)),
            .init(id: "high", title: L10n.Pulse.zoneHigh, color: Color(red: 1.0, green: 0.32, blue: 0.38))
        ]
    }
}

private extension View {
    func pulseCardBackground() -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 10 / 255, green: 28 / 255, blue: 56 / 255).opacity(0.92),
                            Color(red: 6 / 255, green: 20 / 255, blue: 42 / 255).opacity(0.88)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(ProfileTheme.cardBorder.opacity(0.9), lineWidth: 1)
                )
        )
    }
}
