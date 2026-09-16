import SwiftUI

// Drives the two modal steps (scene input / candidate pick) and a failure
// alert. Attach once, on Home.
extension View {
    func scenePortraitOverlay() -> some View { modifier(ScenePortraitOverlayModifier()) }
}

private struct ScenePortraitOverlayModifier: ViewModifier {
    @EnvironmentObject var scenePortrait: ScenePortraitController

    func body(content: Content) -> some View {
        content
            .overlay {
                switch scenePortrait.stage {
                case .sceneInput:
                    ScenePortraitSceneInputView()
                case .candidatePick(_, let candidates):
                    ScenePortraitCandidatePickerView(candidates: candidates)
                default:
                    EmptyView()
                }
            }
            .animation(.easeInOut(duration: 0.28), value: scenePortrait.stage)
            .alert(failedMessage ?? "", isPresented: isFailedPresented) {
                Button("好的") { scenePortrait.dismissError() }
            }
    }

    private var failedMessage: String? {
        if case .failed(let message) = scenePortrait.stage { return message }
        return nil
    }

    private var isFailedPresented: Binding<Bool> {
        Binding(
            get: { failedMessage != nil },
            set: { if !$0 { scenePortrait.dismissError() } }
        )
    }
}
