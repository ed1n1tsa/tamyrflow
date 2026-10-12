import SwiftUI

struct CreateGoalFlowView: View {
    @ObservedObject var service: GoalsService
    var existing: Goal?
    var onDismiss: () -> Void

    @State private var step = 1
    @State private var draft = GoalDraft()
    @State private var showSuccess = false
    @State private var isSaving = false
    @State private var localError: String?
    @State private var reminderDate = Calendar.current.date(from: DateComponents(hour: 9, minute: 0)) ?? Date()

    private let totalSteps = 4
    private var isEditing: Bool { existing != nil }

    var body: some View {
        ZStack {
            GoalsBackgroundView()

            if showSuccess {
                successScreen
            } else {
                VStack(spacing: 0) {
                    header
                        .padding(.top, 8)

                    Group {
                        switch step {
                        case 1: categoryStep
                        case 2: targetStep
                        case 3: periodStep
                        default: remindersStep
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(.top, 20)

                    if let localError {
                        Text(localError)
                            .font(AppFont.interBold(12))
                            .foregroundStyle(AppTheme.danger)
                            .padding(.bottom, 8)
                    }

                    ProfileSetupNavBar(
                        backTitle: L10n.ProfileSetup.back,
                        nextTitle: step == totalSteps
                            ? (isEditing ? L10n.Goals.save : L10n.Goals.createCTA)
                            : L10n.ProfileSetup.next,
                        nextEnabled: canAdvance && !isSaving,
                        onBack: goBack,
                        onNext: { Task { await goNext() } }
                    )
                    .padding(.bottom, 10)
                }
                .padding(.horizontal, ProfileTheme.contentInset)
                .padding(.bottom, 8)
            }
        }
        .onAppear(perform: seedFromExisting)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(isEditing ? L10n.Goals.editTitle : L10n.Goals.createTitle)
                    .font(AppFont.interBold(22))
                    .foregroundStyle(.white)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Circle().fill(Color.white.opacity(0.12)))
                }
                .buttonStyle(.plain)
            }
            ProfileSetupProgress(step: step, total: totalSteps)
        }
    }

    // MARK: - Steps

    private var categoryStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle(L10n.Goals.stepCategoryTitle, L10n.Goals.stepCategorySub)
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(GoalCategory.allCases) { cat in
                    let taken = service.hasCategory(cat) && existing?.category != cat
                    Button {
                        guard !taken else { return }
                        draft.category = cat
                        draft.applyCategoryDefaults()
                    } label: {
                        VStack(spacing: 10) {
                            Image(cat.assetName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 64, height: 64)
                                .opacity(taken ? 0.35 : 1)
                            Text(L10n.Goals.title(for: cat))
                                .font(AppFont.interBold(14))
                                .foregroundStyle(taken ? ProfileTheme.muted : .white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                                .fill(draft.category == cat ? ProfileTheme.accent.opacity(0.22) : ProfileTheme.cardFill)
                                .overlay(
                                    RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                                        .strokeBorder(
                                            draft.category == cat ? ProfileTheme.accent : ProfileTheme.cardBorder,
                                            lineWidth: draft.category == cat ? 2 : 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(taken)
                }
            }
        }
    }

    private var targetStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle(L10n.Goals.stepTargetTitle, L10n.Goals.stepTargetSub(for: draft.category))

            HStack {
                Spacer()
                Text(formattedTarget(draft.targetValue, category: draft.category))
                    .font(AppFont.interBold(40))
                    .foregroundStyle(.white)
                Spacer()
            }
            .padding(.top, 24)

            Group {
                switch draft.category {
                case .steps:
                    Slider(value: $draft.targetValue, in: 1_000...20_000, step: 500)
                case .activity:
                    Slider(value: $draft.targetValue, in: 50...1_000, step: 25)
                case .sleep:
                    Slider(value: $draft.targetValue, in: 4...12, step: 0.5)
                case .water:
                    Slider(value: $draft.targetValue, in: 0.5...5, step: 0.25)
                case .weight:
                    Slider(value: $draft.targetValue, in: 40...150, step: 1)
                }
            }
            .tint(ProfileTheme.accent)
            .padding(.top, 12)

            Text(L10n.Goals.unitHint(for: draft.category))
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.muted)
                .frame(maxWidth: .infinity)
                .padding(.top, 8)
        }
    }

    private var periodStep: some View {
        VStack(alignment: .leading, spacing: 16) {
            stepTitle(L10n.Goals.stepPeriodTitle, L10n.Goals.stepPeriodSub)
            ForEach(GoalPeriod.allCases) { period in
                Button {
                    draft.period = period
                } label: {
                    HStack {
                        Text(L10n.Goals.periodTitle(period))
                            .font(AppFont.interBold(16))
                            .foregroundStyle(.white)
                        Spacer()
                        if draft.period == period {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(ProfileTheme.accent)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                            .fill(draft.period == period ? ProfileTheme.accent.opacity(0.22) : ProfileTheme.cardFill)
                            .overlay(
                                RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                                    .strokeBorder(
                                        draft.period == period ? ProfileTheme.accent : ProfileTheme.cardBorder,
                                        lineWidth: draft.period == period ? 2 : 1
                                    )
                            )
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var remindersStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            stepTitle(L10n.Goals.stepRemindersTitle, L10n.Goals.stepRemindersSub)

            Toggle(isOn: $draft.remindersEnabled) {
                Text(L10n.Goals.remindersToggle)
                    .font(AppFont.interBold(15))
                    .foregroundStyle(.white)
            }
            .tint(ProfileTheme.accent)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                    .fill(ProfileTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                            .strokeBorder(ProfileTheme.cardBorder, lineWidth: 1)
                    )
            )

            if draft.remindersEnabled {
                DatePicker(
                    L10n.Goals.reminderTime,
                    selection: $reminderDate,
                    displayedComponents: .hourAndMinute
                )
                .labelsHidden()
                .datePickerStyle(.wheel)
                .colorScheme(.dark)
                .frame(maxHeight: 140)
                .onChange(of: reminderDate) { _, date in
                    let comps = Calendar.current.dateComponents([.hour, .minute], from: date)
                    draft.reminderHour = comps.hour ?? 9
                    draft.reminderMinute = comps.minute ?? 0
                }

                HStack(spacing: 8) {
                    ForEach(1...7, id: \.self) { day in
                        let selected = draft.reminderDays.contains(day)
                        Button {
                            if selected { draft.reminderDays.remove(day) }
                            else { draft.reminderDays.insert(day) }
                        } label: {
                            Text(L10n.Goals.weekdayShort(day))
                                .font(AppFont.interBold(12))
                                .foregroundStyle(selected ? .white : ProfileTheme.muted)
                                .frame(maxWidth: .infinity)
                                .frame(height: 40)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(selected ? ProfileTheme.accent : Color.white.opacity(0.06))
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private var successScreen: some View {
        VStack(spacing: 22) {
            Spacer()
            Image("GoalSuccess")
                .resizable()
                .scaledToFit()
                .frame(maxWidth: 240, maxHeight: 220)
            Text(L10n.Goals.successTitle)
                .font(AppFont.interBold(26))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            Text(L10n.Goals.successSub)
                .font(AppFont.interBold(14))
                .foregroundStyle(ProfileTheme.muted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Button {
                onDismiss()
            } label: {
                Text(L10n.Goals.done)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Capsule().fill(ProfileTheme.accent))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, ProfileTheme.contentInset)
            .padding(.bottom, 28)
        }
    }

    // MARK: - Helpers

    private func stepTitle(_ title: String, _ subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.interBold(24))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var canAdvance: Bool {
        switch step {
        case 1:
            if let existing, existing.category == draft.category { return true }
            return !service.hasCategory(draft.category)
        case 2: return draft.targetValue > 0
        case 3: return true
        default:
            if draft.remindersEnabled { return !draft.reminderDays.isEmpty }
            return true
        }
    }

    private func goBack() {
        localError = nil
        if step == 1 {
            onDismiss()
        } else {
            step -= 1
        }
    }

    private func goNext() async {
        localError = nil
        if step < totalSteps {
            step += 1
            return
        }

        if draft.remindersEnabled {
            let ok = await GoalNotificationService.requestAuthorizationIfNeeded()
            if !ok {
                localError = L10n.Goals.notificationsDenied
                // Still save goal; reminders stay enabled in DB for later.
            }
        }

        isSaving = true
        defer { isSaving = false }
        do {
            if let existing {
                try await service.update(existing, draft: draft)
                onDismiss()
            } else {
                try await service.create(from: draft)
                withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
                    showSuccess = true
                }
            }
        } catch {
            localError = error.localizedDescription
        }
    }

    private func seedFromExisting() {
        guard let existing else { return }
        draft.category = existing.category
        draft.targetValue = existing.targetValue
        draft.period = existing.period
        draft.remindersEnabled = existing.remindersEnabled
        draft.reminderDays = Set(existing.reminderDays)
        if let t = existing.reminderTime {
            let parts = t.split(separator: ":").compactMap { Int($0) }
            if parts.count >= 2 {
                draft.reminderHour = parts[0]
                draft.reminderMinute = parts[1]
                var c = DateComponents()
                c.hour = parts[0]
                c.minute = parts[1]
                reminderDate = Calendar.current.date(from: c) ?? reminderDate
            }
        }
    }

    private func formattedTarget(_ value: Double, category: GoalCategory) -> String {
        switch category {
        case .steps, .activity, .weight:
            return "\(Int(value.rounded()))"
        case .sleep, .water:
            let n = (value * 10).rounded() / 10
            return n == floor(n) ? "\(Int(n))" : String(format: "%.1f", n)
        }
    }
}
