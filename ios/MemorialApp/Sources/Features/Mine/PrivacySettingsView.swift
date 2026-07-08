import SwiftUI

struct PrivacySettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @State private var visibility: Share.Visibility = .link
    @State private var hugEnabled = true
    @State private var isSaving = false
    @State private var saveError = false

    private var s: Strings { ls.strings }

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            Form {
                Section(s.privacyVisibilitySection) {
                    Picker(s.privacyVisibilityLabel, selection: $visibility) {
                        Text(s.privacyVisibilityLink).tag(Share.Visibility.link)
                        Text(s.privacyVisibilityPrivate).tag(Share.Visibility.private)
                    }
                    .pickerStyle(.inline)
                }
                .listRowBackground(AppColors.white)

                Section {
                    Toggle(s.privacyHugToggle, isOn: $hugEnabled)
                        .tint(AppColors.green)
                } footer: {
                    Text(s.privacyHugFooter)
                        .font(AppFonts.body(12))
                        .foregroundColor(AppColors.muted)
                }
                .listRowBackground(AppColors.white)
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.paper)
        }
        .navigationTitle(s.privacyNavTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button { save() } label: {
                    if isSaving {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Text(s.save)
                            .foregroundColor(AppColors.greenDeep)
                            .fontWeight(.medium)
                    }
                }
                .disabled(isSaving)
            }
        }
        .onAppear {
            visibility = appState.share?.visibility ?? .link
            hugEnabled = appState.share?.hugEnabled ?? true
        }
        .alert(s.saveFailed, isPresented: $saveError) {
            Button(s.ok, role: .cancel) {}
        } message: {
            Text(s.privacySaveError)
        }
    }

    private func save() {
        guard let token = KeychainHelper.loadToken(),
              let petId = appState.currentPet?.id else { return }
        let visStr = visibility == .link ? "LINK" : "PRIVATE"
        let vis = visibility
        let hug = hugEnabled
        isSaving = true
        Task { @MainActor in
            do {
                try await APIClient.shared.updateShare(token: token, petId: petId,
                                                       visibility: visStr, hugEnabled: hug)
                appState.share?.visibility = vis
                appState.share?.hugEnabled = hug
            } catch {
                print("updateShare error: \(error)")
                saveError = true
            }
            isSaving = false
        }
    }
}
