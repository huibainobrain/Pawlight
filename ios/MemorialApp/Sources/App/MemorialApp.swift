import SwiftUI

@main
struct MemorialApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var languageStore = LanguageStore()
    @StateObject private var scenePortrait = ScenePortraitController()
    @StateObject private var companionWindowPiP = CompanionWindowPiPController()
    @StateObject private var planetLife = PlanetLifeController()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(purchaseManager)
                .environmentObject(languageStore)
                .environmentObject(scenePortrait)
                .environmentObject(companionWindowPiP)
                .environmentObject(planetLife)
        }
    }
}
