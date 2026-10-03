import SwiftUI

// PRD §15: "新记录提醒" (开/关) + "暂停星球生活" — pausing only stops future
// generation; history and any Pending gift are explicitly preserved
// (PRD §35), which this view says outright so the toggle doesn't feel risky.
struct PlanetLifeSettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @EnvironmentObject var planetLife: PlanetLifeController
    @Environment(\.dismiss) var dismiss

    @State private var notifyOnNewEvent = true
    @State private var paused = false
    @State private var isSaving = false

    private var s: Strings { ls.strings }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // PlanetLifeCapabilities.pushNotificationsAvailable gates
                    // this toggle — Production must not offer a notification
                    // capability with no real Push behind it yet. The
                    // preference and its save path are untouched, so this
                    // reappears with no other change once Push ships.
                    if PlanetLifeCapabilities.pushNotificationsAvailable {
                        Toggle(s.planetLifeSettingsNotifyToggle, isOn: $notifyOnNewEvent)
                            .onChange(of: notifyOnNewEvent) { _, newValue in
                                Task { await save(notifyOnNewEvent: newValue) }
                            }
                    }
                    Toggle(s.planetLifeSettingsPauseToggle, isOn: $paused)
                        .onChange(of: paused) { _, newValue in
                            Task { await save(paused: newValue) }
                        }
                } footer: {
                    Text(s.planetLifeSettingsPauseFooter)
                }
            }
            .navigationTitle(s.planetLifeSettingsNavTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(s.close) { dismiss() }
                }
            }
            .disabled(isSaving)
            .onAppear {
                notifyOnNewEvent = planetLife.status?.state?.notifyOnNewEvent ?? true
                paused = planetLife.status?.state?.paused ?? false
            }
        }
    }

    private func save(notifyOnNewEvent: Bool? = nil, paused: Bool? = nil) async {
        guard let petId = appState.currentPet?.id, let token = KeychainHelper.loadToken() else { return }
        isSaving = true
        await planetLife.updateSettings(token: token, petId: petId, notifyOnNewEvent: notifyOnNewEvent, paused: paused)
        isSaving = false
    }
}
