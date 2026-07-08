import SwiftUI

@main
struct MemorialApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var languageStore = LanguageStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(purchaseManager)
                .environmentObject(languageStore)
        }
    }
}
