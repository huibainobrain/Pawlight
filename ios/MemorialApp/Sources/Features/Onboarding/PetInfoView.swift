import SwiftUI

struct PetInfoView: View {
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var selectedType: Pet.PetType?
    @State private var navigateToPhoto = false
    @FocusState private var nameFocused: Bool

    private var canContinue: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && selectedType != nil }

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
                    }
                    .padding(.horizontal, 24)
                }

                Button {
                    guard canContinue else { return }
                    navigateToPhoto = true
                } label: {
                    Text("下一步")
                        .font(AppFonts.body(16, weight: .medium))
                        .foregroundColor(canContinue ? AppColors.white : AppColors.muted)
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
        .onAppear { nameFocused = true }
        .navigationDestination(isPresented: $navigateToPhoto) {
            MainPhotoView(petName: name, petType: selectedType ?? .cat)
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
