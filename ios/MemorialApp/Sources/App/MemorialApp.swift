import SwiftUI

@main
struct MemorialApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var languageStore = LanguageStore()
    @StateObject private var promoDemo = PromoDemoController()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(appState)
                .environmentObject(purchaseManager)
                .environmentObject(languageStore)
                .environmentObject(promoDemo)
                .onAppear {
                    appState.promoDemo = promoDemo
                    if promoDemo.needsPetRestore, !appState.hasPet {
                        appState.promoDemoEnterHome()
                    }
                }
        }
    }
}
