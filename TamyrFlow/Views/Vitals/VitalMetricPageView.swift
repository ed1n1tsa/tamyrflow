import SwiftUI

/// Pulse-style detail page for SpO₂ / temperature / blood pressure / steps.
struct VitalMetricPageView: View {
    @EnvironmentObject private var vm: BluetoothViewModel
    @EnvironmentObject private var language: LanguageStore
    @Environment(\.dismiss) private var dismiss

    @StateObject private var service: VitalMetricService
    @State private var selectedPoint: PulseChartPoint?
    @State private var showFullscreenChart = false
    @State private var showHistory = false
    @State private var showConnectWatch = false
    @State private var toast: String?
    @State private var infoSheet = false
    @State private var errorSheetMessage: String?

    init(kind: IndicatorKind, auth: AuthService, health: VeepooHealthService, ble: BleService) {
        _service = StateObject(
            wrappedValue: VitalMetricService(kind: kind, auth: auth, health: health, ble: ble)
        )
    }

    private var accent: Color { service.kind.accent }
    private var iconName: String { service.kind.iconSystemName }

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
                        Spacer(minLength: 0)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(red: 0.05, green: 0.18, blue: 0.12).opacity(0.95))
                    )
                    .padding(.horizontal, 16)
                    .padding(.bottom, 28)
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .navigationBarHidden(true)
        .id(language.code)
        .task { await service.refresh() }
        .onChange(of: service.syncState) { _, state in
            handleSyncState(state)
        }
        .sheet(isPresented: $infoSheet) {
            vitalInfoSheet
        }
        .sheet(item: Binding(
            get: { errorSheetMessage.map { VitalErrorBox(message: $0) } },
            set: { errorSheetMessage = $0?.message }
        )) { box in
            VStack(spacing: 16) {
                Text(L10n.Pulse.sheetErrorTitle)
                    .font(AppFont.interBold(17))
                    .foregroundStyle(.white)
                Text(box.message == "unsupported" ? (L10n.Err.tempUnsupported) : L10n.Pulse.sheetErrorBody)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.muted)
                    .multilineTextAlignment(.center)
                Button(L10n.Pulse.gotIt) { errorSheetMessage = nil }
                    .font(AppFont.interBold(15))
                    .foregroundStyle(ProfileTheme.accent)
            }
            .padding(24)
            .presentationDetents([.medium])
            .presentationBackground(Color(red: 0.04, green: 0.1, blue: 0.2))
        }
        .fullScreenCover(isPresented: $showFullscreenChart) {
            NavigationStack {
                VStack {
                    PulseChartView(
                        points: service.chartPoints,
                        period: service.period,
                        selected: $selectedPoint,
                        emptyMessage: L10n.Pulse.noData,
                        emptySub: service.isWatchConnected ? L10n.Pulse.chartEmptySubConnected : L10n.Pulse.chartEmptySub
                    )
                    .padding()
                }
                .background(GoalsBackgroundView())
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.Pulse.close) { showFullscreenChart = false }
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showHistory) {
            VitalMetricHistoryView(service: service)
        }
        .navigationDestination(isPresented: $showConnectWatch) {
            MyWatchPage()
        }
    }

    // MARK: - Chrome

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
            Text(L10n.Indicators.title(for: service.kind))
                .font(AppFont.interBold(17))
                .foregroundStyle(.white)
            Spacer()

            Button { infoSheet = true } label: {
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
                                            colors: [accent.opacity(0.95), ProfileTheme.accent],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: accent.opacity(0.35), radius: 8, y: 2)
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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.2))
                        .frame(width: 72, height: 72)
                        .shadow(color: accent.opacity(0.45), radius: 12, y: 0)
                    Image(systemName: iconName)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(accent)
                }

                VStack(alignment: .leading, spacing: 5) {
                    Text(L10n.Pulse.lastMeasurement)
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)

                    if let last = service.lastMeasurement {
                        Text(VitalMetricFormatters.displayValue(last, kind: service.kind))
                            .font(AppFont.interBold(28))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                        Text(PulseFormatters.relativeDateTime(last.recordedAt))
                            .font(AppFont.interBold(12))
                            .foregroundStyle(ProfileTheme.muted)
                        Text("\(L10n.Pulse.sourceLabel): \(PulseFormatters.sourceTitle(last.source))")
                            .font(AppFont.interBold(11))
                            .foregroundStyle(ProfileTheme.muted.opacity(0.9))
                    } else {
                        Text(L10n.Pulse.noData)
                            .font(AppFont.interBold(24))
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
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        Image("PulseWatchConnected")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 36, height: 36)
                    } else {
                        Image("PulseWatchDisconnected")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 40, height: 40)
                        Text(L10n.Pulse.watchDisconnected)
                            .font(AppFont.interBold(11))
                            .foregroundStyle(ProfileTheme.muted)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                            .frame(width: 110, alignment: .trailing)
                    }
                }
            }

            if service.isWatchConnected {
                VStack(spacing: 10) {
                    Button {
                        Task { await service.syncAvailableSources() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .font(.system(size: 14, weight: .bold))
                            Text(L10n.Pulse.refreshData)
                                .font(AppFont.interBold(14))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            Capsule(style: .continuous)
                                .fill(ProfileTheme.accent)
                                .shadow(color: ProfileTheme.accent.opacity(0.35), radius: 8, y: 2)
                        )
                    }
                    .buttonStyle(.plain)

                    Button {
                        Task { await service.measureNow() }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: iconName)
                                .font(.system(size: 13, weight: .bold))
                            Text(L10n.Vital.measureNow(for: service.kind))
                                .font(AppFont.interBold(14))
                        }
                        .foregroundStyle(accent)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            Capsule(style: .continuous)
                                .strokeBorder(accent.opacity(0.85), lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
                .disabled(service.syncState == .loading)
                .opacity(service.syncState == .loading ? 0.7 : 1)
            } else {
                Button { showConnectWatch = true } label: {
                    Text(L10n.Pulse.connectWatch)
                        .font(AppFont.interBold(14))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background(
                            Capsule(style: .continuous)
                                .fill(ProfileTheme.accent)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .vitalCardBackground()
    }

    private var averageCard: some View {
        HStack(alignment: .center, spacing: 14) {
            Image(systemName: iconName)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(accent)
                .frame(width: 42, height: 42)
                .background(Circle().fill(accent.opacity(0.18)))

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Vital.averageTitle)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.muted)
                Text(VitalMetricFormatters.displayWithUnit(service.stats.average, kind: service.kind))
                    .font(AppFont.interBold(22))
                    .foregroundStyle(.white)
                if let trend = PulseFormatters.trendText(service.stats.trendPercent, period: service.period) {
                    Text(trend)
                        .font(AppFont.interBold(11))
                        .foregroundStyle(ProfileTheme.connected)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .vitalCardBackground()
    }

    private var dynamicsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Vital.dynamicsTitle)
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
                minMaxTile(title: L10n.Pulse.minimum, value: service.stats.minimum, at: service.stats.minimumAt)
                minMaxTile(title: L10n.Pulse.maximum, value: service.stats.maximum, at: service.stats.maximumAt)
            }
        }
        .padding(16)
        .vitalCardBackground()
    }

    private func minMaxTile(title: String, value: Double?, at: Date?) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(AppFont.interBold(12))
                .foregroundStyle(ProfileTheme.muted)
            Text(VitalMetricFormatters.displayWithUnit(value, kind: service.kind))
                .font(AppFont.interBold(16))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
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
                    HStack(spacing: 12) {
                        Image(systemName: iconName)
                            .foregroundStyle(accent)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(accent.opacity(0.16)))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(VitalMetricFormatters.displayValue(item, kind: service.kind))
                                .font(AppFont.interBold(15))
                                .foregroundStyle(.white)
                            Text("\(PulseFormatters.shortDateTime(item.recordedAt)) · \(PulseFormatters.sourceTitle(item.source))")
                                .font(AppFont.interBold(11))
                                .foregroundStyle(ProfileTheme.muted)
                                .lineLimit(1)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
        }
        .padding(16)
        .vitalCardBackground()
    }

    private var disclaimerCard: some View {
        Button { infoSheet = true } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: iconName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 40, height: 40)
                    .background(Circle().fill(accent.opacity(0.16)))
                Text(L10n.Vital.disclaimer)
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
            .vitalCardBackground()
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
                    Text(L10n.Vital.connectCTATitle)
                        .font(AppFont.interBold(15))
                        .foregroundStyle(.white)
                    Text(L10n.Vital.connectCTABody)
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)
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
        }
        .padding(16)
        .vitalCardBackground()
    }

    private var syncOverlay: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .stroke(accent.opacity(0.25), lineWidth: 5)
                        .frame(width: 72, height: 72)
                    ProgressView()
                        .tint(accent)
                        .scaleEffect(1.3)
                    Image(systemName: iconName)
                        .foregroundStyle(accent)
                }
                Text(service.overlayMode == .measure
                     ? L10n.Vital.measuringTitle(for: service.kind)
                     : L10n.Pulse.syncingTitle)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                Text(service.overlayMode == .measure
                     ? L10n.Vital.measuringBody
                     : L10n.Pulse.syncingBody)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.muted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                Button { service.cancelSyncOverlay() } label: {
                    Text(L10n.Pulse.close)
                        .font(AppFont.interBold(13))
                        .foregroundStyle(ProfileTheme.accent)
                }
                .buttonStyle(.plain)
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(Color(red: 0.04, green: 0.1, blue: 0.2).opacity(0.96))
            )
            .padding(.horizontal, 36)
        }
    }

    private var vitalInfoSheet: some View {
        NavigationStack {
            ScrollView {
                Text(L10n.Vital.sheetAboutBody)
                    .font(AppFont.interBold(14))
                    .foregroundStyle(Color.white.opacity(0.85))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(20)
            }
            .background(Color(red: 0.04, green: 0.1, blue: 0.2).ignoresSafeArea())
            .navigationTitle(L10n.Indicators.title(for: service.kind))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.Pulse.gotIt) { infoSheet = false }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func handleSyncState(_ state: PulseSyncState) {
        switch state {
        case .success:
            withAnimation {
                toast = service.overlayMode == .measure
                    ? L10n.Vital.toastMeasureSuccess
                    : L10n.Pulse.toastSuccess
            }
        case .error(let message):
            errorSheetMessage = message
        case .noSource:
            showConnectWatch = true
        case .noNewData, .idle, .loading:
            break
        }
    }
}

private struct VitalErrorBox: Identifiable {
    let message: String
    var id: String { message }
}

private extension View {
    func vitalCardBackground() -> some View {
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
