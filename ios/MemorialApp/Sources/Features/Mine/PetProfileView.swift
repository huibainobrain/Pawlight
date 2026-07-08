import SwiftUI

struct PetProfileView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @State private var name = ""
    @State private var petType: Pet.PetType = .cat
    @State private var isSaving = false
    @State private var saveError = false

    private var s: Strings { ls.strings }

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            Form {
                Section(s.petProfileBasicSection) {
                    TextField(s.petProfileNameField, text: $name)
                    Picker(s.petProfileTypeField, selection: $petType) {
                        ForEach(Pet.PetType.allCases, id: \.self) { type in
                            Text(s.petTypeName(type)).tag(type)
                        }
                    }
                }
                .listRowBackground(AppColors.white)

                Section(s.petProfileDatesSection) {
                    DatePrecisionRow(label: s.petProfileArrivalDate, notFilled: s.petProfileNotFilled)
                    DatePrecisionRow(label: s.petProfileBirthDate, notFilled: s.petProfileNotFilled)
                    DatePrecisionRow(label: s.petProfileLeftDate, notFilled: s.petProfileNotFilled)
                }
                .listRowBackground(AppColors.white)
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.paper)
        }
        .navigationTitle(s.petProfileNavTitle)
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
                        Text(s.save).foregroundColor(AppColors.greenDeep).fontWeight(.medium)
                    }
                }
                .disabled(isSaving)
            }
        }
        .onAppear {
            name = appState.currentPet?.name ?? ""
            petType = appState.currentPet?.type ?? .cat
        }
        .alert(s.saveFailed, isPresented: $saveError) {
            Button(s.ok, role: .cancel) {}
        } message: {
            Text(s.petProfileSaveError)
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
    let notFilled: String

    var body: some View {
        HStack {
            Text(label)
                .font(AppFonts.body(15))
                .foregroundColor(AppColors.ink)
            Spacer()
            Text(notFilled)
                .font(AppFonts.body(14))
                .foregroundColor(AppColors.muted)
        }
    }
}
