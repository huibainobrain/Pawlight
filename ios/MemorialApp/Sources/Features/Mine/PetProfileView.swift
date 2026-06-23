import SwiftUI

struct PetProfileView: View {
    @EnvironmentObject var appState: AppState
    @State private var name = ""
    @State private var petType: Pet.PetType = .cat
    @State private var isSaving = false
    @State private var saveError = false

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            Form {
                Section("基础信息") {
                    TextField("名字", text: $name)
                    Picker("类型", selection: $petType) {
                        ForEach(Pet.PetType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }
                .listRowBackground(AppColors.white)

                Section("日期（选填）") {
                    DatePrecisionRow(label: "来到身边")
                    DatePrecisionRow(label: "生日")
                    DatePrecisionRow(label: "离开日期")
                }
                .listRowBackground(AppColors.white)
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.paper)
        }
        .navigationTitle("宠物资料")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    save()
                } label: {
                    if isSaving {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Text("保存").foregroundColor(AppColors.greenDeep).fontWeight(.medium)
                    }
                }
                .disabled(isSaving)
            }
        }
        .onAppear {
            name = appState.currentPet?.name ?? ""
            petType = appState.currentPet?.type ?? .cat
        }
        .alert("保存失败", isPresented: $saveError) {
            Button("好的", role: .cancel) {}
        } message: {
            Text("宠物资料暂时没有保存成功，请稍后再试。")
        }
    }

    private func save() {
        isSaving = true
        Task {
            guard let token = KeychainHelper.loadToken(),
                  let petId = appState.currentPet?.id else { isSaving = false; return }
            do {
                try await APIClient.shared.updatePet(token: token, petId: petId, body: [
                    "name": name,
                    "type": petType.rawValue.uppercased()
                ])
                appState.currentPet?.name = name
                appState.currentPet?.type = petType
            } catch {
                print("savePetProfile error: \(error)")
                saveError = true
            }
            isSaving = false
        }
    }
}

struct DatePrecisionRow: View {
    let label: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppFonts.body(15))
                .foregroundColor(AppColors.ink)
            Spacer()
            Text("未填写")
                .font(AppFonts.body(14))
                .foregroundColor(AppColors.muted)
        }
    }
}
