import PhotosUI
import SwiftUI
import UIKit

struct EditProfileView: View {
    @EnvironmentObject private var auth: AuthService
    @EnvironmentObject private var language: LanguageStore
    @EnvironmentObject private var vm: BluetoothViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var displayName = ""
    @State private var gender: ProfileGender = .unspecified
    @State private var age = 20
    @State private var heightCm = 170
    @State private var weightKg = 70
    @State private var avatarURL: String?
    @State private var localAvatarImage: UIImage?

    @State private var photoItem: PhotosPickerItem?
    @State private var showAgeSheet = false
    @State private var showHeightSheet = false
    @State private var showWeightSheet = false
    @State private var showSuccessPopup = false
    @State private var errorText: String?

    var body: some View {
        ZStack {
            ProfileSetupBackground()

            VStack(spacing: 0) {
                navHeader
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 6)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 14) {
                        titleBlock
                        photoCard
                        namedFieldCard
                        genderCard
                        ageCard
                        measureCard(
                            title: L10n.Profile.height,
                            icon: "ruler",
                            value: "\(heightCm)",
                            unit: L10n.ProfileSetup.cmUnit
                        ) {
                            showHeightSheet = true
                        }
                        measureCard(
                            title: L10n.Profile.weight,
                            icon: "scalemass.fill",
                            value: "\(weightKg)",
                            unit: L10n.ProfileSetup.kgUnit
                        ) {
                            showWeightSheet = true
                        }

                        if let errorText {
                            Text(errorText)
                                .font(AppFont.interBold(12))
                                .foregroundStyle(AppTheme.danger)
                        }

                        Button {
                            Task { await save() }
                        } label: {
                            HStack {
                                if auth.isBusy {
                                    ProgressView().tint(.white)
                                }
                                Text(L10n.EditProfile.save)
                                    .font(AppFont.interBold(16))
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                Capsule(style: .continuous)
                                    .fill(canSave ? ProfileTheme.accent : ProfileTheme.accent.opacity(0.4))
                            )
                        }
                        .buttonStyle(.plain)
                        .disabled(!canSave || auth.isBusy)
                        .padding(.top, 8)

                        Button {
                            dismiss()
                        } label: {
                            Text(L10n.EditProfile.cancel)
                                .font(AppFont.interBold(15))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, ProfileTheme.contentInset)
                    .padding(.top, 12)
                }
            }

            if showSuccessPopup {
                successPopup
                    .transition(.opacity.combined(with: .scale(scale: 0.96)))
                    .zIndex(5)
            }
        }
        .navigationBarHidden(true)
        .id(language.code)
        .onAppear(perform: loadFromProfile)
        .onChange(of: photoItem) { _, item in
            guard let item else { return }
            Task { await loadPhoto(item) }
        }
        .sheet(isPresented: $showAgeSheet) {
            wheelSheet(
                title: L10n.ProfileSetup.ageSheetTitle,
                values: Array(10...100),
                selection: $age,
                unit: L10n.ProfileSetup.yearsUnit
            ) {
                showAgeSheet = false
            }
        }
        .sheet(isPresented: $showHeightSheet) {
            wheelSheet(
                title: L10n.Profile.height,
                values: Array(120...220),
                selection: $heightCm,
                unit: L10n.ProfileSetup.cmUnit
            ) {
                showHeightSheet = false
            }
        }
        .sheet(isPresented: $showWeightSheet) {
            wheelSheet(
                title: L10n.Profile.weight,
                values: Array(30...200),
                selection: $weightKg,
                unit: L10n.ProfileSetup.kgUnit
            ) {
                showWeightSheet = false
            }
        }
    }

    private var canSave: Bool {
        !displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Header / title

    private var navHeader: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 36, height: 36)
            }
            .buttonStyle(.plain)

            Spacer()
            Text("TAMYR FLOW")
                .font(AppFont.interBold(14))
                .tracking(1)
                .foregroundStyle(.white)
            Spacer()
            Color.clear.frame(width: 36, height: 36)
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.EditProfile.title)
                .font(AppFont.interBold(26))
                .foregroundStyle(.white)
            Text(L10n.EditProfile.subtitle)
                .font(AppFont.interBold(13))
                .foregroundStyle(ProfileTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: - Cards

    private var photoCard: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            HStack(spacing: 14) {
                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let localAvatarImage {
                            Image(uiImage: localAvatarImage)
                                .resizable()
                                .scaledToFill()
                        } else {
                            ProfileAvatarView(urlString: avatarURL, size: 64)
                        }
                    }
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())

                    Image(systemName: "camera.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Circle().fill(ProfileTheme.accent))
                        .offset(x: 2, y: 2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.EditProfile.photoTitle)
                        .font(AppFont.interBold(15))
                        .foregroundStyle(.white)
                    Text(L10n.EditProfile.photoSub)
                        .font(AppFont.interBold(12))
                        .foregroundStyle(ProfileTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(ProfileTheme.muted)
            }
            .padding(14)
            .editCard()
        }
        .buttonStyle(.plain)
    }

    private var namedFieldCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.EditProfile.nameLabel)
                .font(AppFont.interBold(12))
                .foregroundStyle(ProfileTheme.muted)

            HStack(spacing: 10) {
                Image(systemName: "person.fill")
                    .foregroundStyle(ProfileTheme.accent)
                TextField("", text: $displayName)
                    .font(AppFont.interBold(16))
                    .foregroundStyle(.white)
                    .textInputAutocapitalization(.words)
                if !displayName.isEmpty {
                    Button {
                        displayName = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(ProfileTheme.muted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 14)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(ProfileTheme.cardBorder, lineWidth: 1)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(ProfileTheme.cardFill)
                    )
            )
        }
        .padding(14)
        .editCard()
    }

    private var genderCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.Profile.gender)
                .font(AppFont.interBold(12))
                .foregroundStyle(ProfileTheme.muted)

            HStack(spacing: 8) {
                genderChip(.male, title: L10n.ProfileSetup.genderMale, symbol: "♂")
                genderChip(.female, title: L10n.ProfileSetup.genderFemale, symbol: "♀")
                genderChip(.unspecified, title: L10n.Profile.genderUnspecifiedShort, symbol: "⊘")
            }
        }
        .padding(14)
        .editCard()
    }

    private func genderChip(_ value: ProfileGender, title: String, symbol: String) -> some View {
        let selected = gender == value
        return Button {
            gender = value
        } label: {
            VStack(spacing: 6) {
                Text(symbol)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(selected ? ProfileTheme.accent : ProfileTheme.muted)
                Text(title)
                    .font(AppFont.interBold(11))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.8)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(ProfileTheme.cardFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(selected ? ProfileTheme.accent : ProfileTheme.cardBorder, lineWidth: selected ? 1.5 : 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var ageCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.Profile.age)
                .font(AppFont.interBold(12))
                .foregroundStyle(ProfileTheme.muted)

            Button { showAgeSheet = true } label: {
                HStack(spacing: 10) {
                    Image(systemName: "calendar")
                        .foregroundStyle(ProfileTheme.accent)
                    Text(String(format: L10n.ProfileSetup.ageYearsFormat, age))
                        .font(AppFont.interBold(16))
                        .foregroundStyle(.white)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(ProfileTheme.accent)
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ProfileTheme.cardBorder, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(ProfileTheme.cardFill)
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .editCard()
    }

    private func measureCard(
        title: String,
        icon: String,
        value: String,
        unit: String,
        action: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.interBold(12))
                .foregroundStyle(ProfileTheme.muted)

            Button(action: action) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .foregroundStyle(ProfileTheme.accent)
                    Text(value)
                        .font(AppFont.interBold(16))
                        .foregroundStyle(.white)
                    Spacer()
                    Text(unit)
                        .font(AppFont.interBold(14))
                        .foregroundStyle(ProfileTheme.accent)
                }
                .padding(.horizontal, 14)
                .frame(height: 52)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(ProfileTheme.cardBorder, lineWidth: 1)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(ProfileTheme.cardFill)
                        )
                )
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .editCard()
    }

    // MARK: - Sheets / popup

    private func wheelSheet(
        title: String,
        values: [Int],
        selection: Binding<Int>,
        unit: String,
        onDone: @escaping () -> Void
    ) -> some View {
        VStack(spacing: 0) {
            HStack {
                Button(L10n.ProfileSetup.cancel) { onDone() }
                    .font(AppFont.interBold(15))
                    .foregroundStyle(ProfileTheme.accent)
                Spacer()
                Text(title)
                    .font(AppFont.interBold(17))
                    .foregroundStyle(.white)
                Spacer()
                Button(L10n.ProfileSetup.sheetDone) { onDone() }
                    .font(AppFont.interBold(15))
                    .foregroundStyle(ProfileTheme.accent)
            }
            .padding(.horizontal, 18)
            .padding(.top, 16)

            ProfileWheelPicker(values: values, selection: selection, unit: unit)
                .padding(16)
        }
        .presentationDetents([.height(340)])
        .presentationDragIndicator(.visible)
        .presentationBackground(ProfileTheme.page)
    }

    private var successPopup: some View {
        ZStack {
            Color.black.opacity(0.55).ignoresSafeArea()
            VStack(spacing: 14) {
                Text("TAMYR FLOW")
                    .font(AppFont.interBold(12))
                    .tracking(2)
                    .foregroundStyle(AppTheme.authLink)
                Text(L10n.EditProfile.successTitle)
                    .font(AppFont.interBold(20))
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.center)
                Text(L10n.EditProfile.successBody)
                    .font(AppFont.interBold(14))
                    .foregroundStyle(Color.white.opacity(0.88))
                    .multilineTextAlignment(.center)
                Button {
                    showSuccessPopup = false
                    dismiss()
                } label: {
                    Text(L10n.EditProfile.successOK)
                        .font(AppFont.interBold(15))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Capsule().fill(ProfileTheme.accent))
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(24)
            .frame(maxWidth: 320)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(AppTheme.brandBlueDeep)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(AppTheme.authLink.opacity(0.35), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 28)
        }
    }

    // MARK: - Data

    private func loadFromProfile() {
        guard let p = auth.profile else { return }
        displayName = p.displayName ?? ""
        gender = p.gender ?? .unspecified
        age = p.age ?? 20
        heightCm = p.heightCm ?? 170
        weightKg = Int(p.weightKg?.rounded() ?? 70)
        avatarURL = p.avatarUrl
    }

    private func loadPhoto(_ item: PhotosPickerItem) async {
        errorText = nil
        do {
            guard let data = try await item.loadTransferable(type: Data.self),
                  let image = UIImage(data: data) else {
                errorText = L10n.EditProfile.photoError
                return
            }
            localAvatarImage = image
        } catch {
            errorText = error.localizedDescription
        }
    }

    private func save() async {
        errorText = nil
        guard canSave else { return }

        do {
            var url = avatarURL
            if let localAvatarImage,
               let jpeg = localAvatarImage.jpegData(compressionQuality: 0.82) {
                url = try await auth.uploadAvatarJPEG(jpeg)
                avatarURL = url
            }

            try await auth.updateProfile(
                displayName: displayName,
                gender: gender,
                age: age,
                heightCm: heightCm,
                weightKg: weightKg,
                avatarURL: url,
                locale: language.code.rawValue
            )

            vm.height = "\(heightCm)"
            vm.weight = "\(weightKg)"
            vm.age = "\(age)"
            switch gender {
            case .female: vm.sex = 0
            case .male: vm.sex = 1
            case .unspecified: break
            }

            withAnimation(.easeInOut(duration: 0.2)) {
                showSuccessPopup = true
            }
        } catch {
            errorText = error.localizedDescription
        }
    }
}

private extension View {
    func editCard() -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                    .fill(ProfileTheme.cardFill.opacity(0.55))
                    .overlay(
                        RoundedRectangle(cornerRadius: ProfileTheme.cardRadius, style: .continuous)
                            .stroke(ProfileTheme.cardBorder, lineWidth: 1)
                    )
            )
    }
}
