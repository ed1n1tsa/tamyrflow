import SwiftUI

struct ActivityPageView: View {
    @EnvironmentObject private var vm: BluetoothViewModel
    @EnvironmentObject private var auth: AuthService
    @Binding var selectedTab: MainTab
    @StateObject private var service: ActivityService
    @State private var showAdd = false
    @State private var showCalendar = false
    @State private var calendarDate = Date()
    /// Avoid flashing the empty hero while Supabase/band sync is still in flight after tab recreate.
    @State private var didFinishInitialLoad = false

    init(auth: AuthService, selectedTab: Binding<MainTab>) {
        _service = StateObject(wrappedValue: ActivityService(auth: auth))
        _selectedTab = selectedTab
    }

    var body: some View {
        ZStack {
            GoalsBackgroundView()

            VStack(spacing: 0) {
                header
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 8)

                weekStrip
                    .padding(.top, 14)

                Group {
                    if !didFinishInitialLoad || (service.isLoading && service.isEmptyDay) {
                        ProgressView().tint(.white).frame(maxHeight: .infinity)
                    } else if service.isEmptyDay {
                        ActivityEmptyStateView(
                            onAdd: { showAdd = true },
                            onOpenGoals: { selectedTab = .goals },
                            hasGoals: !service.activeGoals.isEmpty,
                            goals: service.activeGoals
                        )
                    } else {
                        ActivityDashboardView(
                            service: service,
                            onAdd: { showAdd = true },
                            onOpenGoals: { selectedTab = .goals }
                        )
                    }
                }
            }
        }
        .task {
            // 1) Paint cached Supabase day first (steps/kcal already saved).
            await service.refresh()
            didFinishInitialLoad = true
            // 2) Then quietly refresh from the band and reload.
            await vm.syncActivityMetricsToCloud(auth: auth)
            await service.refresh()
        }
        .refreshable {
            await vm.syncActivityMetricsToCloud(auth: auth)
            await service.refresh()
            didFinishInitialLoad = true
        }
        .fullScreenCover(isPresented: $showAdd) {
            AddActivityFlowView(service: service) {
                showAdd = false
            }
        }
        .sheet(isPresented: $showCalendar) {
            NavigationStack {
                DatePicker(
                    "",
                    selection: $calendarDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(ProfileTheme.accent)
                .padding()
                .navigationTitle(L10n.Activity.pickDate)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.Goals.done) {
                            showCalendar = false
                            Task { await service.selectDate(calendarDate) }
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .preferredColorScheme(.dark)
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.Activity.screenTitle)
                    .font(AppFont.interBold(28))
                    .foregroundStyle(.white)
                Text(service.isEmptyDay ? L10n.Activity.subtitleEmpty : L10n.Activity.subtitleFilled)
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Button {
                calendarDate = service.selectedDate
                showCalendar = true
            } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(ProfileTheme.cardFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
                            )
                    )
            }
            .buttonStyle(.plain)
        }
    }

    private var weekStrip: some View {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())
        // Show 7 days around selected (Mon-based week containing selected).
        let weekday = cal.component(.weekday, from: service.selectedDate)
        let iso = weekday == 1 ? 7 : weekday - 1
        let weekStart = cal.date(byAdding: .day, value: -(iso - 1), to: cal.startOfDay(for: service.selectedDate)) ?? today

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                ForEach(0..<7, id: \.self) { offset in
                    let day = cal.date(byAdding: .day, value: offset, to: weekStart) ?? today
                    let selected = cal.isDate(day, inSameDayAs: service.selectedDate)
                    Button {
                        Task { await service.selectDate(day) }
                    } label: {
                        VStack(spacing: 6) {
                            Text(L10n.Activity.weekdayShort(cal.component(.weekday, from: day)))
                                .font(AppFont.interBold(12))
                            Text("\(cal.component(.day, from: day))")
                                .font(AppFont.interBold(16))
                        }
                        .foregroundStyle(.white)
                        .frame(width: 52, height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(selected ? ProfileTheme.accent.opacity(0.35) : ProfileTheme.cardFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .strokeBorder(selected ? ProfileTheme.accent : ProfileTheme.cardBorder, lineWidth: selected ? 2 : 1)
                                )
                                .shadow(color: selected ? ProfileTheme.accent.opacity(0.45) : .clear, radius: 8, y: 0)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, ProfileTheme.contentInset)
        }
    }
}
