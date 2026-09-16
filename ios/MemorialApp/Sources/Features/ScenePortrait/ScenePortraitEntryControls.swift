import SwiftUI

// Small entry/revert affordances shown near (not on top of) the observation
// window's photo circle, so the existing "tap the circle -> Memory tab"
// gesture is never disturbed. Paid-only; entry point is fully invisible to
// free users (server also enforces this independently — see
// ScenePortraitsService.startJob).
struct ScenePortraitEntryButton: View {
    @EnvironmentObject var scenePortrait: ScenePortraitController
    @EnvironmentObject var ls: LanguageStore

    private var s: Strings { ls.strings }

    var body: some View {
        Button {
            scenePortrait.beginSceneInput()
        } label: {
            Text(s.scenePortraitEntryBtn)
                .font(AppFonts.body(12, weight: .medium))
                .foregroundColor(AppColors.green)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(AppColors.green.opacity(0.10))
                .clipShape(Capsule())
        }
    }
}

struct ScenePortraitRevertButton: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @State private var isReverting = false

    private var s: Strings { ls.strings }

    var body: some View {
        Button {
            revert()
        } label: {
            Text(isReverting ? s.scenePortraitReverting : s.scenePortraitRevertBtn)
                .font(AppFonts.body(12, weight: .medium))
                .foregroundColor(AppColors.muted)
                .padding(.horizontal, 14)
                .padding(.vertical, 7)
                .background(AppColors.muted.opacity(0.08))
                .clipShape(Capsule())
        }
        .disabled(isReverting)
    }

    private func revert() {
        guard let token = KeychainHelper.loadToken(), let petId = appState.currentPet?.id else { return }
        isReverting = true
        Task {
            try? await APIClient.shared.revertObservationWindow(token: token, petId: petId)
            await appState.loadCurrentPet()
            isReverting = false
        }
    }
}
