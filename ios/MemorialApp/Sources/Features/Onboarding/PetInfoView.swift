import SwiftUI

struct PetInfoView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var selectedType: Pet.PetType?
    @State private var navigateToPhoto = false
    @State private var createdPetId: String?
    @State private var isCreating = false
    @State private var createError: String?
    @State private var showExitAlert = false
    @FocusState private var nameFocused: Bool

    private var canContinue: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && selectedType != nil && !isCreating
    }

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                StepIndicator(current: 1, total: 3)
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 32) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("1 / 3  基础信息")
                                .font(AppFonts.body(13))
                                .foregroundColor(AppColors.muted)
                            Text("TA叫什么名字？")
                                .font(AppFonts.serif(24, weight: .medium))
                                .foregroundColor(AppColors.ink)
                        }
                        .padding(.top, 28)

                        VStack(alignment: .leading, spacing: 12) {
                            Text("名字")
                                .font(AppFonts.body(14, weight: .medium))
                                .foregroundColor(AppColors.ink)
                            TextField("TA的名字", text: $name)
                                .font(AppFonts.body(16))
                                .padding(.horizontal, 16)
                                .padding(.vertical, 14)
                                .background(AppColors.white)
                                .cornerRadius(10)
                                .overlay(RoundedRectangle(cornerRadius: 10).stroke(AppColors.line, lineWidth: 1))
                                .focused($nameFocused)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("TA是")
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

                        if let error = createError {
                            Text(error)
                                .font(AppFonts.body(13))
                                .foregroundColor(AppColors.rose)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Button {
                    guard canContinue else { return }
                    createPetAndNavigate()
                } label: {
                    HStack(spacing: 8) {
                        if isCreating {
                            ProgressView().tint(canContinue ? AppColors.white : AppColors.muted)
                        }
                        Text(isCreating ? "创建中..." : "下一步")
                            .font(AppFonts.body(16, weight: .medium))
                            .foregroundColor(canContinue ? AppColors.white : AppColors.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(canContinue ? AppColors.greenDeep : AppColors.line)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .disabled(!canContinue)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(!name.trimmingCharacters(in: .whitespaces).isEmpty)
        .toolbar {
            if !name.trimmingCharacters(in: .whitespaces).isEmpty {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showExitAlert = true
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("返回")
                        }
                        .foregroundColor(AppColors.greenDeep)
                    }
                }
            }
        }
        .alert("暂时离开？", isPresented: $showExitAlert) {
            Button("继续创建", role: .cancel) {}
            Button("先离开", role: .destructive) { dismiss() }
        } message: {
            Text("现在离开的话，本次填写的内容不会保存。")
        }
        .onAppear { nameFocused = true }
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
                let petId = try await appState.createPet(name: name, type: selectedType!)
                createdPetId = petId
                navigateToPhoto = true
            } catch {
                createError = "创建失败，请重试"
                print("createPet error: \(error)")
            }
            isCreating = false
        }
    }
}

struct PetTypeButton: View {
    let type: Pet.PetType
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(type.displayName)
                .font(AppFonts.body(14, weight: isSelected ? .medium : .regular))
                .foregroundColor(isSelected ? AppColors.greenDeep : AppColors.muted)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(isSelected ? AppColors.green.opacity(0.12) : AppColors.white)
                .cornerRadius(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isSelected ? AppColors.green : AppColors.line, lineWidth: isSelected ? 1.5 : 1)
                )
        }
    }
}

struct StepIndicator: View {
    let current: Int
    let total: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<total, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(i <= current ? AppColors.greenDeep : AppColors.line)
                    .frame(height: 3)
            }
        }
    }
}
