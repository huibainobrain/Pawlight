import SwiftUI

// MARK: - Main View

struct PetInfoView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedType: Pet.PetType?
    @State private var navigateToPhoto = false
    @State private var createdPetId: String?
    @State private var isCreating = false
    @State private var createError: String?
    @State private var showExitAlert = false
    @FocusState private var nameFocused: Bool

    private var s: Strings { ls.strings }

    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && selectedType != nil && !isCreating
    }

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            VStack(spacing: 0) {

                // Progress bar
                StepIndicator(current: 0, total: 3)
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {

                        // Header: step label + title + ambient illustration
                        ZStack(alignment: .topLeading) {
                            // Ambient circle bleeds off the right edge
                            HStack(spacing: 0) {
                                Spacer()
                                PetInfoAmbientCircle()
                                    .padding(.trailing, -48)
                            }
                            .allowsHitTesting(false)

                            // Step info and title
                            VStack(alignment: .leading, spacing: 10) {
                                Text(s.petInfoStep)
                                    .font(AppFonts.body(12))
                                    .foregroundColor(AppColors.green)

                                Text(s.petInfoTitle)
                                    .font(AppFonts.serif(26, weight: .medium))
                                    .foregroundColor(AppColors.ink)
                                    .fixedSize(horizontal: false, vertical: true)

                                Text(s.petInfoBody)
                                    .font(AppFonts.body(14))
                                    .foregroundColor(AppColors.muted)
                                    .lineSpacing(4)
                                    .padding(.trailing, 108)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.top, 24)

                        // Name input
                        VStack(alignment: .leading, spacing: 10) {
                            Text(s.petInfoNameLabel)
                                .font(AppFonts.body(14, weight: .medium))
                                .foregroundColor(AppColors.ink)

                            VStack(alignment: .leading, spacing: 0) {
                                TextField(s.petInfoNamePlaceholder, text: $name)
                                    .font(AppFonts.body(16))
                                    .foregroundColor(AppColors.ink)
                                    .padding(.horizontal, 18)
                                    .padding(.top, 18)
                                    .padding(.bottom, 10)
                                    .focused($nameFocused)

                                HStack {
                                    Spacer()
                                    Text("\(name.count)/20")
                                        .font(AppFonts.body(11))
                                        .foregroundColor(AppColors.muted.opacity(0.48))
                                        .padding(.trailing, 16)
                                        .padding(.bottom, 12)
                                }
                            }
                            .background(AppColors.white)
                            .cornerRadius(14)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(
                                        nameFocused ? AppColors.green.opacity(0.45) : AppColors.line,
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                        }

                        // Pet type selection
                        VStack(alignment: .leading, spacing: 12) {
                            Text(s.petInfoTypeLabel)
                                .font(AppFonts.body(14, weight: .medium))
                                .foregroundColor(AppColors.ink)

                            HStack(spacing: 12) {
                                ForEach(Pet.PetType.allCases, id: \.self) { type in
                                    PetTypeButton(type: type, isSelected: selectedType == type) {
                                        selectedType = type
                                    }
                                }
                            }
                        }

                        // Error
                        if let error = createError {
                            Text(error)
                                .font(AppFonts.body(13))
                                .foregroundColor(AppColors.rose)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }

                // Bottom CTA
                VStack(spacing: 12) {
                    Button {
                        guard canContinue else { return }
                        createPetAndNavigate()
                    } label: {
                        HStack(spacing: 8) {
                            if isCreating {
                                ProgressView().tint(canContinue ? AppColors.white : AppColors.muted)
                            }
                            Text(isCreating ? s.creating : s.next)
                                .font(AppFonts.body(16, weight: .medium))
                                .foregroundColor(canContinue ? AppColors.white : AppColors.muted)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(canContinue ? AppColors.greenDeep.opacity(0.86) : AppColors.line)
                        .cornerRadius(14)
                        .shadow(
                            color: canContinue ? AppColors.greenDeep.opacity(0.10) : .clear,
                            radius: 8, x: 0, y: 3
                        )
                    }
                    .disabled(!canContinue)

                    HStack(spacing: 5) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 8))
                            .foregroundColor(AppColors.muted.opacity(0.32))
                        Image(systemName: "lock.fill")
                            .font(.system(size: 9))
                            .foregroundColor(AppColors.muted.opacity(0.38))
                        Text(s.petInfoCanChange)
                            .font(AppFonts.body(12))
                            .foregroundColor(AppColors.muted.opacity(0.52))
                        Image(systemName: "sparkle")
                            .font(.system(size: 8))
                            .foregroundColor(AppColors.muted.opacity(0.32))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 40)
            }
        }
        .navigationBarBackButtonHidden(true)
        .disableSwipeBack()
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                        showExitAlert = true
                    } else {
                        dismiss()
                    }
                } label: {
                    ZStack {
                        Circle()
                            .fill(AppColors.white)
                            .frame(width: 34, height: 34)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.ink)
                    }
                }
            }
        }
        .alert(s.petInfoExitTitle, isPresented: $showExitAlert) {
            Button(s.petInfoContinue, role: .cancel) {}
            Button(s.leaveBtn, role: .destructive) { dismiss() }
        } message: {
            Text(s.petInfoExitBody)
        }
        .onAppear { nameFocused = true }
        .onChange(of: name) { _, newValue in
            if newValue.count > 20 { name = String(newValue.prefix(20)) }
        }
        .navigationDestination(isPresented: $navigateToPhoto) {
            if let petId = createdPetId {
                MainPhotoView(petId: petId, petName: name, petType: selectedType ?? .cat)
            }
        }
    }

    private func createPetAndNavigate() {
        isCreating = true
        createError = nil
        Task { @MainActor in
            do {
                if let petId = createdPetId {
                    // Already created earlier in this session — user came back to edit
                    // name/type. Update the existing pet instead of creating a new one
                    // (V1 backend enforces one pet per user).
                    guard let token = KeychainHelper.loadToken() else { throw APIError.noToken }
                    try await APIClient.shared.updatePet(token: token, petId: petId, body: [
                        "name": name,
                        "type": selectedType!.rawValue.uppercased(),
                    ])
                } else {
                    createdPetId = try await appState.createPet(name: name, type: selectedType!)
                }
                navigateToPhoto = true
            } catch {
                createError = s.petInfoCreateError
                print("createPet/updatePet error: \(error)")
            }
            isCreating = false
        }
    }
}

// MARK: - Ambient Illustration

private struct PetInfoAmbientCircle: View {
    var body: some View {
        ZStack {
            // Scene inside the circle
            ZStack {
                // Sky gradient
                LinearGradient(
                    colors: [
                        Color(red: 0.92, green: 0.96, blue: 0.97).opacity(0.90),
                        Color(red: 0.86, green: 0.92, blue: 0.88).opacity(0.90),
                        Color(red: 0.76, green: 0.86, blue: 0.78).opacity(0.85),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Hill
                GeometryReader { geo in
                    let w = geo.size.width, h = geo.size.height
                    Path { p in
                        p.move(to: CGPoint(x: 0, y: h * 0.70))
                        p.addCurve(
                            to: CGPoint(x: w, y: h * 0.66),
                            control1: CGPoint(x: w * 0.28, y: h * 0.50),
                            control2: CGPoint(x: w * 0.70, y: h * 0.76)
                        )
                        p.addLine(to: CGPoint(x: w, y: h))
                        p.addLine(to: CGPoint(x: 0, y: h))
                        p.closeSubpath()
                    }
                    .fill(Color(red: 0.52, green: 0.66, blue: 0.46).opacity(0.48))
                }

                // Paw prints — decorative, low opacity
                Image(systemName: "pawprint.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(red: 0.65, green: 0.58, blue: 0.50).opacity(0.30))
                    .offset(x: 14, y: 30)

                Image(systemName: "pawprint.fill")
                    .font(.system(size: 11))
                    .foregroundColor(Color(red: 0.65, green: 0.58, blue: 0.50).opacity(0.18))
                    .offset(x: -24, y: 44)

                // Single soft star
                Image(systemName: "sparkle")
                    .font(.system(size: 12, weight: .ultraLight))
                    .foregroundColor(Color.white.opacity(0.80))
                    .offset(x: 4, y: -44)
            }
            .frame(width: 158, height: 158)
            .clipShape(Circle())

            // Rim light
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.white.opacity(0.82), AppColors.green.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 2
                )
                .frame(width: 158, height: 158)
        }
        .frame(width: 178, height: 178)
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }
}

// MARK: - Pet Type Card

struct PetTypeButton: View {
    let type: Pet.PetType
    let isSelected: Bool
    let action: () -> Void
    @EnvironmentObject var ls: LanguageStore

    private var iconName: String {
        switch type {
        case .cat:   return "cat.fill"
        case .dog:   return "dog.fill"
        case .other: return "pawprint.fill"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: iconName)
                    .font(.system(size: 26))
                    .foregroundColor(isSelected ? AppColors.greenDeep : AppColors.muted.opacity(0.60))
                Text(ls.strings.petTypeName(type))
                    .font(AppFonts.body(13, weight: isSelected ? .medium : .regular))
                    .foregroundColor(isSelected ? AppColors.greenDeep : AppColors.muted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(isSelected ? AppColors.green.opacity(0.08) : AppColors.white)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        isSelected ? AppColors.green.opacity(0.55) : AppColors.line,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
        }
    }
}

// MARK: - Step Indicator

struct StepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<total, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(i <= current ? AppColors.greenDeep.opacity(0.78) : AppColors.muted.opacity(0.15))
                    .frame(height: 3.5)
            }
        }
    }
}
