import SwiftUI

/// Metrics tab: period filters + indicator cards with sparklines.
struct IndicatorsPageView: View {
    @EnvironmentObject private var language: LanguageStore
    @StateObject private var service: IndicatorsService
    @State private var showCalendar = false
    @State private var calendarDate = Date()
    @State private var detailKind: IndicatorKind?
    @State private var errorAlert: String?

    init(auth: AuthService) {
        _service = StateObject(wrappedValue: IndicatorsService(auth: auth))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                GoalsBackgroundView()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        header
                        periodPills
                        dateRangeButton

                        LazyVStack(spacing: 12) {
                            ForEach(service.cards) { card in
                                Button {
                                    detailKind = card.kind
                                } label: {
                                    IndicatorCardView(card: card)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 2)
                    }
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 6)
                    .padding(.bottom, 32)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(item: $detailKind) { kind in
                detailDestination(for: kind)
            }
        }
        .id(language.code)
        .task { await service.refresh() }
        .refreshable { await service.refresh() }
        .sheet(isPresented: $showCalendar) {
            NavigationStack {
                DatePicker(
                    "",
                    selection: $calendarDate,
                    in: ...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(ProfileTheme.accent)
                .padding()
                .navigationTitle(L10n.Indicators.pickDate)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.Goals.done) {
                            showCalendar = false
                            Task { await service.setRangeEnd(calendarDate) }
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .preferredColorScheme(.dark)
        }
        .onChange(of: service.lastError) { _, err in
            if let err { errorAlert = err }
        }
        .alert(L10n.Goals.errorTitle, isPresented: Binding(
            get: { errorAlert != nil },
            set: { if !$0 { errorAlert = nil } }
        )) {
            Button(L10n.Goals.ok, role: .cancel) { errorAlert = nil }
        } message: {
            Text(errorAlert ?? "")
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    BrandLogoMark()
                    Text("TAMYR FLOW")
                        .font(AppFont.interBold(15))
                        .tracking(1.2)
                        .foregroundStyle(.white)
                }
                Spacer()
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(ProfileTheme.cardFill)
                                .overlay(
                                    Circle().strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
                                )
                        )
                    Circle()
                        .fill(AppTheme.danger)
                        .frame(width: 8, height: 8)
                        .offset(x: -2, y: 2)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(L10n.Indicators.screenTitle)
                    .font(AppFont.interBold(32))
                    .foregroundStyle(.white)
                Text(L10n.Indicators.subtitle)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineSpacing(2)
            }
        }
    }

    // MARK: - Period / date

    private var periodPills: some View {
        HStack(spacing: 8) {
            ForEach(IndicatorsPeriod.allCases) { period in
                let selected = service.period == period
                Button {
                    Task { await service.setPeriod(period) }
                } label: {
                    Text(L10n.Indicators.periodLabel(period))
                        .font(AppFont.interBold(14))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .background {
                            if selected {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
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
                                    .shadow(color: ProfileTheme.accent.opacity(0.45), radius: 10, y: 3)
                            } else {
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .fill(Color(red: 8 / 255, green: 28 / 255, blue: 56 / 255).opacity(0.75))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(ProfileTheme.cardBorder.opacity(0.85), lineWidth: 1)
                                    )
                            }
                        }
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var dateRangeButton: some View {
        Button {
            calendarDate = service.rangeEnd
            showCalendar = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "calendar")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ProfileTheme.muted)
                Text(formattedRange)
                    .font(AppFont.interBold(14))
                    .foregroundStyle(.white)
                Spacer(minLength: 8)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(ProfileTheme.muted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 8 / 255, green: 28 / 255, blue: 56 / 255).opacity(0.75))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(ProfileTheme.cardBorder.opacity(0.85), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var formattedRange: String {
        let localeId = LanguageStoreBootstrap.bundle.preferredLocalizations.first ?? "ru"
        let locale = Locale(identifier: localeId)
        let start = service.rangeStart
        let end = service.rangeEnd
        let cal = Calendar.current

        let dayMonth: DateFormatter = {
            let f = DateFormatter()
            f.locale = locale
            f.setLocalizedDateFormatFromTemplate("d MMM")
            return f
        }()
        let dayMonthYear: DateFormatter = {
            let f = DateFormatter()
            f.locale = locale
            f.setLocalizedDateFormatFromTemplate("d MMM yyyy")
            return f
        }()

        if cal.isDate(start, equalTo: end, toGranularity: .year) {
            return "\(dayMonth.string(from: start)) – \(dayMonthYear.string(from: end))"
        }
        return "\(dayMonthYear.string(from: start)) – \(dayMonthYear.string(from: end))"
    }

    @ViewBuilder
    private func detailDestination(for kind: IndicatorKind) -> some View {
        switch kind {
        case .heartRate:
            HeartRatePage()
        case .spo2:
            OxygenPage()
        case .temperature:
            TemperaturePage()
        case .bloodPressure, .steps, .sleep:
            VitalsPage()
        }
    }
}
