import SwiftUI

struct AddActivityFlowView: View {
    @ObservedObject var service: ActivityService
    var onDismiss: () -> Void

    @State private var step = 1
    @State private var draft = ActivityDraft()
    @State private var filter = "all"
    @State private var query = ""
    @State private var showSuccess = false
    @State private var isSaving = false
    @State private var localError: String?
    @State private var showDatePicker = false

    private let totalSteps = 4

    var body: some View {
        ZStack {
            GoalsBackgroundView()

            if showSuccess {
                successScreen
            } else {
                VStack(spacing: 0) {
                    topBar
                        .padding(.horizontal, ProfileTheme.contentInset)
                        .padding(.top, 8)

                    ScrollView(showsIndicators: false) {
                        Group {
                            switch step {
                            case 1: categoryStep
                            case 2: typeStep
                            case 3: detailsStep
                            default: reviewStep
                            }
                        }
                        .padding(.horizontal, ProfileTheme.contentInset)
                        .padding(.top, 18)
                        .padding(.bottom, 20)
                    }

                    if let localError {
                        Text(localError)
                            .font(AppFont.interBold(12))
                            .foregroundStyle(AppTheme.danger)
                            .padding(.bottom, 6)
                    }

                    bottomBar
                        .padding(.horizontal, ProfileTheme.contentInset)
                        .padding(.bottom, 16)
                }
            }
        }
        .sheet(isPresented: $showDatePicker) {
            NavigationStack {
                DatePicker("", selection: $draft.startedAt)
                    .datePickerStyle(.graphical)
                    .tint(ProfileTheme.accent)
                    .padding()
                    .navigationTitle(L10n.Activity.dateTime)
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(L10n.Goals.done) { showDatePicker = false }
                        }
                    }
            }
            .preferredColorScheme(.dark)
            .presentationDetents([.medium, .large])
        }
    }

    // MARK: - Chrome

    private var topBar: some View {
        HStack {
            Button {
                if step == 1 { onDismiss() } else { step -= 1 }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Spacer()
            Text(L10n.Activity.addTitle)
                .font(AppFont.interBold(17))
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
    }

    private var bottomBar: some View {
        Button {
            Task { await goNext() }
        } label: {
            Text(step == totalSteps ? L10n.Activity.addCTA : L10n.Activity.continueCTA)
                .font(AppFont.interBold(16))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Capsule().fill(canAdvance && !isSaving ? ProfileTheme.accent : ProfileTheme.accent.opacity(0.35)))
        }
        .buttonStyle(.plain)
        .disabled(!canAdvance || isSaving)
    }

    // MARK: - Steps

    private var categoryStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader(1, L10n.Activity.stepCategoryTitle, L10n.Activity.stepCategorySub)
            ForEach(ActivityCategory.allCases) { cat in
                Button {
                    draft.category = cat
                } label: {
                    HStack(spacing: 14) {
                        Image(cat.assetName)
                            .resizable().scaledToFit().frame(width: 48, height: 48)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.Activity.categoryTitle(cat))
                                .font(AppFont.interBold(16)).foregroundStyle(.white)
                            Text(L10n.Activity.categorySub(cat))
                                .font(AppFont.interBold(12)).foregroundStyle(ProfileTheme.muted)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .foregroundStyle(ProfileTheme.muted)
                    }
                    .padding(14)
                    .background(cardBg(selected: draft.category == cat))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var typeStep: some View {
        VStack(alignment: .leading, spacing: 14) {
            stepHeader(2, L10n.Activity.stepTypeTitle, L10n.Activity.stepTypeSub)

            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(ProfileTheme.muted)
                TextField(L10n.Activity.searchPlaceholder, text: $query)
                    .foregroundStyle(.white)
            }
            .padding(12)
            .background(cardBg(selected: false))

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(["all", "strength", "cardio", "sport"], id: \.self) { key in
                        Button {
                            filter = key
                        } label: {
                            Text(L10n.Activity.filterTitle(key))
                                .font(AppFont.interBold(12))
                                .foregroundStyle(filter == key ? .white : ProfileTheme.muted)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    Capsule().fill(filter == key ? ProfileTheme.accent : Color.white.opacity(0.06))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            ForEach(filteredTypes) { type in
                Button { draft.type = type } label: {
                    HStack(spacing: 14) {
                        Image(type.assetName)
                            .resizable().scaledToFit().frame(width: 44, height: 44)
                        Text(L10n.Activity.typeTitle(type))
                            .font(AppFont.interBold(15)).foregroundStyle(.white)
                        Spacer()
                        if draft.type == type {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(ProfileTheme.accent)
                        }
                    }
                    .padding(12)
                    .background(cardBg(selected: draft.type == type))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader(3, L10n.Activity.stepDetailsTitle, L10n.Activity.stepDetailsSub)

            HStack {
                Image(draft.type.assetName)
                    .resizable().scaledToFit().frame(width: 44, height: 44)
                Text(L10n.Activity.typeTitle(draft.type))
                    .font(AppFont.interBold(16)).foregroundStyle(.white)
                Spacer()
                Button(L10n.Activity.change) { step = 2 }
                    .font(AppFont.interBold(13))
                    .foregroundStyle(ProfileTheme.accent)
            }
            .padding(14)
            .background(cardBg(selected: false))

            VStack(spacing: 10) {
                Text(L10n.Activity.duration)
                    .font(AppFont.interBold(14)).foregroundStyle(ProfileTheme.muted)
                HStack(spacing: 24) {
                    stepperButton(systemImage: "minus") {
                        draft.durationMin = max(5, draft.durationMin - 5)
                    }
                    Text("\(draft.durationMin) \(L10n.Activity.minUnit)")
                        .font(AppFont.interBold(28)).foregroundStyle(.white)
                        .frame(minWidth: 120)
                    stepperButton(systemImage: "plus") {
                        draft.durationMin = min(300, draft.durationMin + 5)
                    }
                }
            }
            .padding(16)
            .background(cardBg(selected: false))

            Button { showDatePicker = true } label: {
                HStack {
                    Image(systemName: "calendar")
                        .foregroundStyle(ProfileTheme.accent)
                    Text(dateLabel(draft.startedAt))
                        .font(AppFont.interBold(14)).foregroundStyle(.white)
                    Spacer()
                    Text(timeOnly(draft.startedAt))
                        .font(AppFont.interBold(14)).foregroundStyle(ProfileTheme.muted)
                    Image(systemName: "chevron.right")
                        .foregroundStyle(ProfileTheme.muted)
                }
                .padding(14)
                .background(cardBg(selected: false))
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.Activity.intensity)
                    .font(AppFont.interBold(14)).foregroundStyle(ProfileTheme.muted)
                HStack(spacing: 8) {
                    ForEach(ActivityIntensity.allCases) { level in
                        Button { draft.intensity = level } label: {
                            Text(L10n.Activity.intensityTitle(level))
                                .font(AppFont.interBold(13))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    Capsule().fill(draft.intensity == level ? ProfileTheme.accent : Color.white.opacity(0.06))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(14)
            .background(cardBg(selected: false))

            VStack(alignment: .leading, spacing: 8) {
                Text(L10n.Activity.notes)
                    .font(AppFont.interBold(14)).foregroundStyle(ProfileTheme.muted)
                TextField(L10n.Activity.notesPlaceholder, text: $draft.notes, axis: .vertical)
                    .lineLimit(3...5)
                    .foregroundStyle(.white)
                Text("\(draft.notes.count)/200")
                    .font(AppFont.interBold(11))
                    .foregroundStyle(ProfileTheme.muted)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(14)
            .background(cardBg(selected: false))
            .onChange(of: draft.notes) { _, v in
                if v.count > 200 { draft.notes = String(v.prefix(200)) }
            }
        }
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepHeader(4, L10n.Activity.stepReviewTitle, L10n.Activity.stepReviewSub)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Image(draft.type.assetName)
                        .resizable().scaledToFit().frame(width: 44, height: 44)
                    Text(L10n.Activity.typeTitle(draft.type))
                        .font(AppFont.interBold(16)).foregroundStyle(.white)
                    Spacer()
                    Button(L10n.Activity.change) { step = 2 }
                        .font(AppFont.interBold(13))
                        .foregroundStyle(ProfileTheme.accent)
                }

                reviewRow(systemImage: "clock", title: L10n.Activity.duration, value: "\(draft.durationMin) \(L10n.Activity.minUnit)")
                reviewRow(systemImage: "calendar", title: L10n.Activity.dateTime, value: "\(dateLabel(draft.startedAt)) · \(timeOnly(draft.startedAt))")
                reviewRow(systemImage: "chart.bar.fill", title: L10n.Activity.intensity, value: L10n.Activity.intensityTitle(draft.intensity))
                if !draft.notes.isEmpty {
                    reviewRow(systemImage: "note.text", title: L10n.Activity.notes, value: draft.notes)
                }
            }
            .padding(16)
            .background(cardBg(selected: false))

            Button { step = 3 } label: {
                Text(L10n.ProfileSetup.back)
                    .font(AppFont.interBold(15))
                    .foregroundStyle(ProfileTheme.muted)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
    }

    private var successScreen: some View {
        VStack(spacing: 20) {
            Spacer()
            Image("GoalSuccess")
                .resizable().scaledToFit()
                .frame(maxWidth: 220, maxHeight: 200)
            Text(L10n.Activity.successTitle)
                .font(AppFont.interBold(26)).foregroundStyle(.white)
            Text(L10n.Activity.successSub)
                .font(AppFont.interBold(14)).foregroundStyle(ProfileTheme.muted)

            VStack(alignment: .leading, spacing: 10) {
                reviewRow(systemImage: "figure.run", title: L10n.Activity.activityLabel, value: L10n.Activity.typeTitle(draft.type))
                reviewRow(systemImage: "clock", title: L10n.Activity.duration, value: "\(draft.durationMin) \(L10n.Activity.minUnit)")
                reviewRow(systemImage: "calendar", title: L10n.Activity.dateTime, value: "\(dateLabel(draft.startedAt)) · \(timeOnly(draft.startedAt))")
                reviewRow(systemImage: "chart.bar.fill", title: L10n.Activity.intensity, value: L10n.Activity.intensityTitle(draft.intensity))
            }
            .padding(16)
            .background(cardBg(selected: false))
            .padding(.horizontal, ProfileTheme.contentInset)

            Spacer()

            Button(action: onDismiss) {
                Text(L10n.Activity.viewInActivity)
                    .font(AppFont.interBold(16)).foregroundStyle(.white)
                    .frame(maxWidth: .infinity).frame(height: 54)
                    .background(Capsule().fill(ProfileTheme.accent))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, ProfileTheme.contentInset)

            Button {
                showSuccess = false
                step = 1
                draft = ActivityDraft()
            } label: {
                Text(L10n.Activity.addAnother)
                    .font(AppFont.interBold(15))
                    .foregroundStyle(ProfileTheme.accent)
                    .frame(maxWidth: .infinity).frame(height: 50)
                    .background(
                        Capsule().strokeBorder(ProfileTheme.accent, lineWidth: 1.2)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, ProfileTheme.contentInset)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Helpers

    private var filteredTypes: [ActivityTypeKey] {
        ActivityTypeKey.allCases.filter { type in
            let matchesFilter = filter == "all" || type.filterGroup == filter || (filter == "sport" && type == .yoga)
            let q = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let matchesQuery = q.isEmpty || L10n.Activity.typeTitle(type).lowercased().contains(q)
            return matchesFilter && matchesQuery
        }
    }

    private var canAdvance: Bool {
        switch step {
        case 1, 2: return true
        case 3: return draft.durationMin > 0
        default: return true
        }
    }

    private func goNext() async {
        localError = nil
        if step < totalSteps {
            step += 1
            return
        }
        isSaving = true
        defer { isSaving = false }
        do {
            try await service.create(from: draft)
            withAnimation { showSuccess = true }
        } catch {
            localError = error.localizedDescription
        }
    }

    private func stepHeader(_ n: Int, _ title: String, _ sub: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(n). \(title)")
                .font(AppFont.interBold(22)).foregroundStyle(.white)
            Text(sub)
                .font(AppFont.interBold(13)).foregroundStyle(ProfileTheme.muted)
        }
    }

    private func cardBg(selected: Bool) -> some View {
        RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
            .fill(selected ? ProfileTheme.accent.opacity(0.2) : ProfileTheme.cardFill)
            .overlay(
                RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                    .strokeBorder(selected ? ProfileTheme.accent : ProfileTheme.cardBorder, lineWidth: selected ? 2 : 1)
            )
    }

    private func stepperButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(Circle().fill(ProfileTheme.accent.opacity(0.85)))
        }
        .buttonStyle(.plain)
    }

    private func reviewRow(systemImage: String, title: String, value: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .foregroundStyle(ProfileTheme.accent)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.interBold(12)).foregroundStyle(ProfileTheme.muted)
                Text(value)
                    .font(AppFont.interBold(14)).foregroundStyle(.white)
            }
            Spacer()
        }
    }

    private func dateLabel(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: LanguageStoreBootstrap.bundle.preferredLocalizations.first ?? "ru")
        if Calendar.current.isDateInToday(date) {
            f.dateFormat = "d MMMM"
            return String(format: L10n.Activity.todayDate, f.string(from: date))
        }
        f.dateFormat = "d MMMM"
        return f.string(from: date)
    }

    private func timeOnly(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }
}
