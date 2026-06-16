import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        switch appState.ownerStage {
        case .unauthenticated, .loggedInNoPet:
            OnboardingStartView()
        case .hasPetFree, .hasPetPaid:
            MainTabView()
        }
    }
}
