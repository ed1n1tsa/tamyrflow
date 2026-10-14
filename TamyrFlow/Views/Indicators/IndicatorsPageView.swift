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
                    VStack(alignment: .leading, spacing: 16) {
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
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 8)
                    .padding(.bottom, 28)
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

            Text(L10n.Indicators.screenTitle)
                .font(AppFont.interBold(30))
                .foregroundStyle(.white)
            Text(L10n.Indicators.subtitle)
                .font(AppFont.interBold(14))
                .foregroundStyle(ProfileTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
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
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selected ? ProfileTheme.accent : ProfileTheme.cardFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(
                                            selected ? ProfileTheme.accent : ProfileTheme.cardBorder,
                                            lineWidth: 1
                                        )
                                )
                        )
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
            HStack(spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(ProfileTheme.muted)
                Text(formattedRange)
                    .font(AppFont.interBold(14))
                    .foregroundStyle(.white)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(ProfileTheme.muted)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ProfileTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
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
