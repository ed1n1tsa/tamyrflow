import SwiftUI

/// Product home — connected / disconnected watch hero + indicators (Figma).
struct DashboardPage: View {
    @EnvironmentObject private var vm: BluetoothViewModel
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var language: LanguageStore
    @Binding var selectedTab: MainTab

    @StateObject private var indicators: IndicatorsService
    @State private var activityPeriod: HomeActivityPeriod = .week
    @State private var showConnectWatch = false
    @State private var showMyWatch = false

    init(selectedTab: Binding<MainTab>, auth: AuthService) {
        _selectedTab = selectedTab
        _indicators = StateObject(wrappedValue: IndicatorsService(auth: auth))
    }

    private var isWatchConnected: Bool {
        switch vm.bleService.connectionStatus {
        case .connected, .verified: return true
        default: return false
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 16) {
                    header
                    watchCard
                    indicatorsSection
                    activitySection
                }
                .padding(.horizontal, ProfileTheme.contentInset)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            // Background fills under the status bar; ScrollView content keeps safe area
            // (a sibling ZStack + ignoresSafeArea previously shoved the logo/watch off-screen).
            .background {
                HomeBackgroundView()
            }
            .toolbar(.hidden, for: .navigationBar)
            .toolbarBackground(.hidden, for: .navigationBar)
            .task {
                await vm.performPullToRefresh(auth: auth)
                await indicators.refresh()
            }
            .onAppear {
                Task { await indicators.refresh() }
            }
            .refreshable {
                // Never leave a stuck measuring HUD after Home pull.
                vm.healthService.dismissMeasurementOverlay()
                await vm.performPullToRefresh(auth: auth)
                await indicators.refresh()
            }
            .id(language.code)
            .navigationDestination(isPresented: $showMyWatch) {
                MyWatchPage()
            }
            .fullScreenCover(isPresented: $showConnectWatch) {
                WatchConnectFlowView {
                    showConnectWatch = false
                }
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    BrandLogoMark()
                    Text("TAMYR FLOW")
                        .font(AppFont.interBold(18))
                        .tracking(1.1)
                        .foregroundStyle(.white)
                }
                Text(L10n.Home.tagline)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.muted)
            }
            Spacer()
            ZStack(alignment: .topTrailing) {
                Image(systemName: "bell.fill")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(ProfileTheme.cardFill)
                            .overlay(Circle().strokeBorder(ProfileTheme.cardBorder, lineWidth: 1))
                    )
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .offset(x: -4, y: 4)
            }
        }
    }

    // MARK: - Watch card

    @ViewBuilder
    private var watchCard: some View {
        if isWatchConnected {
            Button { showMyWatch = true } label: {
                connectedWatchCard
            }
            .buttonStyle(.plain)
        } else {
            disconnectedWatchCard
        }
    }

    private var connectedWatchCard: some View {
        HStack(spacing: 14) {
            Image("HomeWatchConnected")
                .resizable()
                .scaledToFit()
                .frame(width: 88, height: 88)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 6) {
                    Circle().fill(ProfileTheme.connected).frame(width: 7, height: 7)
                    Text(L10n.Home.watchConnected)
                        .font(AppFont.interBold(15))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(ProfileTheme.muted)
                }
                Text(watchDisplayName)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.muted)
                    .lineLimit(1)

                Label(vm.batteryText, systemImage: "battery.100")
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.connected)

                // Own row so “Sync: Today, 18:23” is never clipped by battery/chevron.
                Label(syncLabel, systemImage: "arrow.triangle.2.circlepath")
                    .font(AppFont.interBold(11))
                    .foregroundStyle(ProfileTheme.accentSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .homeGlassCard()
    }

    private var disconnectedWatchCard: some View {
        HStack(alignment: .center, spacing: 14) {
            Image("HomeWatchDisconnected")
                .resizable()
                .scaledToFit()
                .frame(width: 86, height: 110)

            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.Home.watchDisconnected)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                Text(L10n.Home.watchDisconnectedBody)
                    .font(AppFont.interBold(12))
                    .foregroundStyle(ProfileTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 8) {
                    Button { showConnectWatch = true } label: {
                        Text(L10n.Home.connectWatch)
                            .font(AppFont.interBold(13))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule().fill(ProfileTheme.accent)
                                    .shadow(color: ProfileTheme.accent.opacity(0.45), radius: 8, y: 2)
                            )
                    }
                    .buttonStyle(.plain)

                    Button { showMyWatch = true } label: {
                        Text(L10n.Home.moreDetails)
                            .font(AppFont.interBold(13))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
                                    .background(Capsule().fill(Color.white.opacity(0.04)))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(14)
        .homeGlassCard()
    }

    // MARK: - Indicators

    private var indicatorsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Home.mainIndicators)
                    .font(AppFont.interBold(17))
                    .foregroundStyle(.white)
                Spacer()
                Button { selectedTab = .metrics } label: {
                    Text(L10n.Home.allData)
                        .font(AppFont.interBold(13))
                        .foregroundStyle(ProfileTheme.accent)
                }
                .buttonStyle(.plain)
            }

            NavigationLink {
                PulsePageView(auth: auth, health: vm.healthService, ble: vm.bleService)
            } label: {
                pulseCard
            }
            .buttonStyle(.plain)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                NavigationLink {
                    VitalMetricPageView(
                        kind: .spo2,
                        auth: auth,
                        health: vm.healthService,
                        ble: vm.bleService
                    )
                } label: {
                    smallMetricCard(
                        title: L10n.Home.oxygen,
                        value: oxygenText,
                        subtitle: statSubtitle(for: .spo2, unit: "%"),
                        tint: Color(red: 0.25, green: 0.65, blue: 1.0),
                        icon: "drop.fill"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    VitalMetricPageView(
                        kind: .temperature,
                        auth: auth,
                        health: vm.healthService,
                        ble: vm.bleService
                    )
                } label: {
                    smallMetricCard(
                        title: L10n.Home.temperature,
                        value: temperatureText,
                        subtitle: statSubtitle(for: .temperature, unit: "°C"),
                        tint: Color(red: 1.0, green: 0.55, blue: 0.2),
                        icon: "thermometer.medium"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    VitalMetricPageView(
                        kind: .bloodPressure,
                        auth: auth,
                        health: vm.healthService,
                        ble: vm.bleService
                    )
                } label: {
                    smallMetricCard(
                        title: L10n.Home.pressure,
                        value: pressureText,
                        subtitle: statSubtitle(for: .bloodPressure, unit: "mmHg"),
                        tint: Color(red: 0.7, green: 0.4, blue: 1.0),
                        icon: "waveform.path.ecg"
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    VitalMetricPageView(
                        kind: .steps,
                        auth: auth,
                        health: vm.healthService,
                        ble: vm.bleService
                    )
                } label: {
                    stepsCard
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var pulseCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.22))
                    .frame(width: 54, height: 54)
                    .shadow(color: Color.red.opacity(0.45), radius: 10, y: 0)
                Image(systemName: "heart.fill")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Color.red)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.Home.pulse)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.muted)
                Text(pulseText)
                    .font(AppFont.interBold(28))
                    .foregroundStyle(.white)
                Text(pulseStatLine)
                    .font(AppFont.interBold(11))
                    .foregroundStyle(ProfileTheme.muted)
            }

            Spacer(minLength: 8)

            if let trend = card(for: .heartRate)?.trendPercent {
                trendChip(trend)
            }
        }
        .padding(16)
        .homeGlassCard()
    }

    private func smallMetricCard(
        title: String,
        value: String,
        subtitle: String,
        tint: Color,
        icon: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(tint.opacity(0.18)))
                Spacer()
            }
            Text(title)
                .font(AppFont.interBold(12))
                .foregroundStyle(ProfileTheme.muted)
            Text(value)
                .font(AppFont.interBold(20))
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(subtitle)
                .font(AppFont.interBold(11))
                .foregroundStyle(ProfileTheme.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .homeGlassCard()
    }

    private func trendChip(_ trend: Double) -> some View {
        let up = trend >= 0
        return HStack(spacing: 4) {
            Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 10, weight: .bold))
            Text(String(format: "%+.0f%%", trend))
                .font(AppFont.interBold(11))
        }
        .foregroundStyle(up ? ProfileTheme.connected : Color.orange)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill((up ? ProfileTheme.connected : Color.orange).opacity(0.16))
        )
    }

    private var stepsCard: some View {
        let steps = vm.healthService.todaySteps
        let target = 10_000
        let ratio = steps.map { min(1, Double($0) / Double(target)) } ?? 0

        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "figure.walk")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(red: 0.2, green: 0.85, blue: 0.65))
                    .frame(width: 28, height: 28)
                    .background(Circle().fill(Color(red: 0.2, green: 0.85, blue: 0.65).opacity(0.18)))
                Spacer()
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: ratio)
                        .stroke(Color(red: 0.2, green: 0.85, blue: 0.65), style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text(steps == nil ? "—" : "\(Int(ratio * 100))%")
                        .font(AppFont.interBold(9))
                        .foregroundStyle(.white)
                }
                .frame(width: 36, height: 36)
            }
            Text(L10n.Home.steps)
                .font(AppFont.interBold(12))
                .foregroundStyle(ProfileTheme.muted)
            if let steps {
                Text("\(formatInt(steps))")
                    .font(AppFont.interBold(20))
                    .foregroundStyle(.white)
                Text(String(format: L10n.Home.stepsOf, formatInt(target)))
                    .font(AppFont.interBold(11))
                    .foregroundStyle(ProfileTheme.muted)
            } else {
                Text(L10n.Home.noData)
                    .font(AppFont.interBold(20))
                    .foregroundStyle(.white)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .topLeading)
        .homeGlassCard()
    }

    // MARK: - Activity

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L10n.Home.activity)
                    .font(AppFont.interBold(17))
                    .foregroundStyle(.white)
                Spacer()
                activityPeriodPills
            }

            ZStack {
                HomeWeekBars(values: weekBarValues, highlightIndex: highlightIndex)
                    .frame(height: 160)
                    .padding(.top, 8)

                if weekBarValues.allSatisfy({ $0 <= 0 }) {
                    VStack(spacing: 10) {
                        Image(systemName: "applewatch")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(ProfileTheme.accent)
                        Text(L10n.Home.noActivityData)
                            .font(AppFont.interBold(13))
                            .foregroundStyle(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.black.opacity(0.55))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(ProfileTheme.cardBorder.opacity(0.6), lineWidth: 1)
                            )
                    )
                }
            }
            .padding(14)
            .homeGlassCard()
        }
    }

    private var activityPeriodPills: some View {
        HStack(spacing: 4) {
            ForEach(HomeActivityPeriod.allCases) { period in
                Button {
                    activityPeriod = period
                } label: {
                    Text(period.title)
                        .font(AppFont.interBold(11))
                        .foregroundStyle(activityPeriod == period ? .white : ProfileTheme.muted)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(
                            Capsule()
                                .fill(activityPeriod == period ? ProfileTheme.accent : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Capsule().fill(Color.white.opacity(0.06)))
    }

    // MARK: - Data helpers

    private var watchDisplayName: String {
        let name = vm.currentDeviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty || name == "-" { return "Tamyr Watch" }
        return name
    }

    private var syncLabel: String {
        if let at = vm.healthService.lastDailySyncAt {
            if Calendar.current.isDateInToday(at) {
                return "\(L10n.Home.syncPrefix): \(L10n.Home.syncToday), \(Self.shortTime.string(from: at))"
            }
            return "\(L10n.Home.syncPrefix): \(Self.shortTime.string(from: at))"
        }
        return "\(L10n.Home.syncPrefix): —"
    }

    private func card(for kind: IndicatorKind) -> IndicatorCardModel? {
        indicators.cards.first(where: { $0.kind == kind })
    }

    private var pulseValue: Int? {
        if let hr = vm.healthService.heartRate?.value, (30...250).contains(hr) { return hr }
        if let last = vm.healthService.heartRateHistory.last?.value, last >= 30 {
            return Int(last.rounded())
        }
        if let stored = card(for: .heartRate)?.primaryValue, stored >= 30 {
            return Int(stored.rounded())
        }
        return nil
    }

    private var pulseText: String {
        if let v = pulseValue { return "\(v)" }
        return L10n.Home.noData
    }

    private var pulseStatLine: String {
        if pulseValue != nil {
            if let trend = card(for: .heartRate)?.trendPercent {
                return "\(L10n.Home.bpm) · \(String(format: "%+.0f%%", trend))"
            }
            return L10n.Home.bpm
        }
        return L10n.Home.statsFromHistory
    }

    private var oxygenText: String {
        if let v = vm.healthService.oxygen?.value, v > 0 { return "\(v)%" }
        if let stored = card(for: .spo2)?.primaryValue, stored > 0 {
            return "\(Int(stored.rounded()))%"
        }
        return L10n.Home.noData
    }

    private var pressureText: String {
        if let bp = vm.healthService.bloodPressure,
           bp.systolic > 0, bp.diastolic > 0 {
            return "\(bp.systolic)/\(bp.diastolic)"
        }
        if let card = card(for: .bloodPressure), let sys = card.primaryValue, sys > 0 {
            if let dia = card.secondaryValue, dia > 0 {
                return "\(Int(sys.rounded()))/\(Int(dia.rounded()))"
            }
            return "\(Int(sys.rounded()))"
        }
        return L10n.Home.noData
    }

    private var temperatureText: String {
        if let body = vm.healthService.temperature?.bodyTemperature, body > 30 {
            return String(format: "%.1f °C", body)
        }
        if let last = vm.healthService.bodyTemperatureHistory.last?.value, last > 30 {
            return String(format: "%.1f °C", last)
        }
        if let stored = card(for: .temperature)?.primaryValue, stored > 30 {
            return String(format: "%.1f °C", stored)
        }
        return L10n.Home.noData
    }

    private func statSubtitle(for kind: IndicatorKind, unit: String) -> String {
        guard let card = card(for: kind), card.primaryValue != nil else {
            return L10n.Home.statsFromHistory
        }
        if let trend = card.trendPercent {
            return "\(unit) · \(String(format: "%+.0f%%", trend))"
        }
        return unit
    }

    private var weekBarValues: [Double] {
        // Prefer 7-day steps series from Supabase; fall back to today's realtime band steps.
        if let series = card(for: .steps)?.series, series.count >= 7 {
            let last7 = Array(series.suffix(7))
            return last7.map(\.value)
        }
        var vals = Array(repeating: 0.0, count: 7)
        if let steps = vm.healthService.todaySteps, steps > 0 {
            let idx = (Calendar.current.component(.weekday, from: Date()) + 5) % 7 // Mon=0
            vals[idx] = Double(steps)
        }
        return vals
    }

    private var highlightIndex: Int? {
        let idx = (Calendar.current.component(.weekday, from: Date()) + 5) % 7
        guard weekBarValues.indices.contains(idx) else { return nil }
        return weekBarValues[idx] > 0 ? idx : nil
    }

    private func formatInt(_ n: Int) -> String {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        f.groupingSeparator = " "
        return f.string(from: NSNumber(value: n)) ?? "\(n)"
    }

    private static let shortTime: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ru_RU")
        f.dateFormat = "HH:mm"
        return f
    }()
}

// MARK: - Models / helpers

enum HomeActivityPeriod: String, CaseIterable, Identifiable {
    case day, week, month
    var id: String { rawValue }
    var title: String {
        switch self {
        case .day: return L10n.Home.periodDay
        case .week: return L10n.Home.periodWeek
        case .month: return L10n.Home.periodMonth
        }
    }
}

private struct HomeWeekBars: View {
    let values: [Double]
    let highlightIndex: Int?

    private var labels: [String] {
        [
            L10n.Home.weekdayMon, L10n.Home.weekdayTue, L10n.Home.weekdayWed,
            L10n.Home.weekdayThu, L10n.Home.weekdayFri, L10n.Home.weekdaySat, L10n.Home.weekdaySun
        ]
    }

    var body: some View {
        GeometryReader { geo in
            let maxV = max(values.max() ?? 1, 1)
            let barW = (geo.size.width - 6 * 8) / 7
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<7, id: \.self) { i in
                    let h = max(8, CGFloat(values[i] / maxV) * (geo.size.height - 22))
                    let on = highlightIndex == i
                    VStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: on
                                        ? [ProfileTheme.accent, Color.cyan.opacity(0.7)]
                                        : [ProfileTheme.accent.opacity(0.55), ProfileTheme.accent.opacity(0.2)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: barW, height: h)
                            .shadow(color: on ? ProfileTheme.accent.opacity(0.55) : .clear, radius: 8, y: 0)
                        Text(labels[i])
                            .font(AppFont.interBold(10))
                            .foregroundStyle(on ? .white : ProfileTheme.muted)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                }
            }
        }
    }
}

private extension View {
    func homeGlassCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 6 / 255, green: 18 / 255, blue: 40 / 255).opacity(0.78))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        ProfileTheme.cardBorder.opacity(0.95),
                                        ProfileTheme.cardBorder.opacity(0.35)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
}
