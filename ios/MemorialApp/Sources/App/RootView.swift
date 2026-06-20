import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            switch appState.ownerStage {
            case .unauthenticated, .loggedInNoPet:
                OnboardingStartView()
            case .hasPetFree, .hasPetPaid:
                MainTabView()
            }
        }
        .task {
            await appState.checkAuthAndLoad()
        }
    }
}
