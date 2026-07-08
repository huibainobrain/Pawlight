import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        Group {
            if appState.isAuthChecking {
                AppColors.paper.ignoresSafeArea()
            } else if appState.hasPet {
                MainTabView()
            } else if appState.hasSkippedOnboarding {
                MainTabView()
            } else {
                OnboardingStartView(onSkip: { appState.hasSkippedOnboarding = true })
            }
        }
        .task {
            await appState.checkAuthAndLoad()
        }
    }
}
