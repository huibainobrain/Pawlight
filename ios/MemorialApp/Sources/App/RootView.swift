import SwiftUI

struct RootView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        MainTabView()
            .task {
                await appState.checkAuthAndLoad()
            }
    }
}
