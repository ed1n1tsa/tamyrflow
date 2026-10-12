import SwiftUI

/// Post-registration wizard: name → gender → age → height → weight.
struct ProfileSetupFlowView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var language: LanguageStore
    @EnvironmentObject private var vm: BluetoothViewModel

    var onFinished: () -> Void
    var onCancelToAuth: () -> Void

    @State private var step = 1
    @State private var draft = ProfileSetupDraft()
    @State private var showAgeSheet = false

    private let totalSteps = 5

    var body: some View {
        ZStack {
            ProfileSetupBackground()

            VStack(spacing: 0) {
                header
                    .padding(.top, 8)

                Group {
                    switch step {
                    case 1: nameStep
                    case 2: genderStep
                    case 3: ageStep
                    case 4: heightStep
                    default: weightStep
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .padding(.top, 22)
                .id("\(language.code)-\(step)")

                if let err = auth.lastError, step == totalSteps {
                    Text(err)
                        .font(AppFont.interBold(12))
                        .foregroundStyle(AppTheme.danger)
                        .padding(.bottom, 8)
                }

                ProfileSetupNavBar(
                    backTitle: L10n.ProfileSetup.back,
                    nextTitle: step == totalSteps ? L10n.ProfileSetup.done : L10n.ProfileSetup.next,
                    nextEnabled: canAdvance && !auth.isBusy,
                    onBack: goBack,
                    onNext: {
                        Task { await goNext() }
                    }
                )
                .padding(.bottom, 10)
            }
            .padding(.horizontal, ProfileTheme.contentInset)
            .padding(.bottom, 8)
        }
        .sheet(isPresented: $showAgeSheet) {
            ageSheet
                .presentationDetents([.height(340)])
                .presentationDragIndicator(.visible)
                .presentationBackground(ProfileTheme.page)
        }
        .onAppear {
            if draft.displayName.isEmpty {
                draft.displayName = auth.profile?.displayName
                    ?? auth.session?.user.email?.split(separator: "@").first.map(String.init)
                    ?? ""
            }
        }
    }

    // MARK: - Shared header

    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                BrandLogoMark()
                Text("TAMYR FLOW")
                    .font(AppFont.interBold(16))
                    .tracking(1.1)
                    .foregroundStyle(.white)
                Spacer()
            }
            ProfileSetupProgress(step: step, total: totalSteps)
        }
    }

    private func stepTitle(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.interBold(28))
                .foregroundStyle(.white)
            Text(subtitle)
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Steps

    private var nameStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            stepTitle(L10n.ProfileSetup.nameTitle, subtitle: L10n.ProfileSetup.nameSub)
            HStack(spacing: 12) {
                Image("ProfileAvatar")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
                TextField("", text: $draft.displayName, prompt: Text(L10n.ProfileSetup.namePlaceholder).foregroundColor(ProfileTheme.muted))
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                    .textInputAutocapitalization(.words)
            }
            .padding(.horizontal, 14)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(ProfileTheme.cardBorder, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(ProfileTheme.cardFill)
                    )
            )
            Spacer(minLength: 0)
        }
    }

    private var genderStep: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(L10n.ProfileSetup.sectionProfile)
                .font(AppFont.interBold(12))
                .foregroundStyle(ProfileTheme.muted)
            stepTitle(L10n.ProfileSetup.genderTitle, subtitle: L10n.ProfileSetup.genderSub)

            VStack(spacing: 10) {
                genderRow(.male, title: L10n.ProfileSetup.genderMale, icon: "♂")
                genderRow(.female, title: L10n.ProfileSetup.genderFemale, icon: "♀")
                genderRow(.unspecified, title: L10n.ProfileSetup.genderUnspecified, icon: "⊘")
            }
            Spacer(minLength: 0)
        }
    }

    private func genderRow(_ value: ProfileGender, title: String, icon: String) -> some View {
        let selected = draft.gender == value
        return Button {
            draft.gender = value
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(selected ? ProfileTheme.accent.opacity(0.25) : Color.white.opacity(0.06))
                        .frame(width: 40, height: 40)
                    Text(icon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(selected ? ProfileTheme.accent : ProfileTheme.muted)
                }
                Text(title)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                Spacer()
                ZStack {
                    Circle()
                        .strokeBorder(selected ? ProfileTheme.accent : ProfileTheme.cardBorder, lineWidth: 2)
                        .frame(width: 22, height: 22)
                    if selected {
                        Circle()
                            .fill(ProfileTheme.accent)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 64)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(ProfileTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selected ? ProfileTheme.accent : ProfileTheme.cardBorder, lineWidth: selected ? 1.5 : 1)
                    )
            )
            .shadow(color: selected ? ProfileTheme.accent.opacity(0.35) : .clear, radius: 8, y: 0)
        }
        .buttonStyle(.plain)
    }

    private var ageStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            stepTitle(L10n.ProfileSetup.ageTitle, subtitle: L10n.ProfileSetup.ageSub)
            Button { showAgeSheet = true } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(ProfileTheme.accent)
                        .frame(width: 36, height: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(ProfileTheme.accent.opacity(0.18))
                        )
                    Text(String(format: L10n.ProfileSetup.ageYearsFormat, draft.age))
                        .font(AppFont.interBold(18))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(ProfileTheme.accent)
                }
                .padding(.horizontal, 14)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(ProfileTheme.cardBorder, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(ProfileTheme.cardFill)
                        )
                )
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
    }

    private var ageSheet: some View {
        VStack(spacing: 0) {
            HStack {
                Button(L10n.ProfileSetup.cancel) { showAgeSheet = false }
                    .font(AppFont.interBold(15))
                    .foregroundStyle(ProfileTheme.accent)
                Spacer()
                Text(L10n.ProfileSetup.ageSheetTitle)
                    .font(AppFont.interBold(17))
                    .foregroundStyle(.white)
                Spacer()
                Button(L10n.ProfileSetup.sheetDone) { showAgeSheet = false }
                    .font(AppFont.interBold(15))
                    .foregroundStyle(ProfileTheme.accent)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)

            ProfileWheelPicker(values: Array(10...100), selection: $draft.age, unit: L10n.ProfileSetup.yearsUnit)
                .padding(16)
        }
    }

    private var heightStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            stepTitle(L10n.ProfileSetup.heightTitle, subtitle: L10n.ProfileSetup.heightSub)
            ProfileWheelPicker(values: Array(120...220), selection: $draft.heightCm, unit: L10n.ProfileSetup.cmUnit)
            Spacer(minLength: 0)
        }
    }

    private var weightStep: some View {
        VStack(alignment: .leading, spacing: 22) {
            stepTitle(L10n.ProfileSetup.weightTitle, subtitle: L10n.ProfileSetup.weightSub)
            ProfileWheelPicker(values: Array(30...200), selection: $draft.weightKg, unit: L10n.ProfileSetup.kgUnit)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Navigation

    private var canAdvance: Bool {
        switch step {
        case 1: return !draft.displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 2: return draft.gender != nil
        default: return true
        }
    }

    private func goBack() {
        auth.lastError = nil
        if step == 1 {
            onCancelToAuth()
        } else {
            withAnimation(.easeInOut(duration: 0.22)) { step -= 1 }
        }
    }

    private func goNext() async {
        auth.lastError = nil
        guard canAdvance else { return }
        if step < totalSteps {
            withAnimation(.easeInOut(duration: 0.22)) { step += 1 }
            return
        }

        do {
            try await auth.completeProfileSetup(draft, locale: language.code.rawValue)
            // Sync into BLE personal info used by the band SDK.
            vm.height = "\(draft.heightCm)"
            vm.weight = "\(draft.weightKg)"
            vm.age = "\(draft.age)"
            switch draft.gender {
            case .female: vm.sex = 0
            case .male: vm.sex = 1
            default: break
            }
            onFinished()
        } catch {
            auth.lastError = error.localizedDescription
        }
    }
}
