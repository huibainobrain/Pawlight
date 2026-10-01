import SwiftUI
import AVFoundation
import UIKit

// Loading/looping-video content for the observation window. Plays a remote
// R2 URL directly via AVQueuePlayer + AVPlayerLooper (no local temp-file
// materialization needed, since the source is already a URL).
struct ScenePortraitObservationContent: View {
    let stage: ScenePortraitController.Stage
    let videoUrl: String?

    var body: some View {
        if stage.isGenerating {
            ScenePortraitLoadingView()
        } else if let videoUrl, let url = URL(string: videoUrl) {
            ScenePortraitLoopingVideoView(url: url)
        } else {
            ScenePortraitLoadingView()
        }
    }
}

private struct ScenePortraitLoadingView: View {
    @State private var breathe = false

    var body: some View {
        ZStack {
            Circle().fill(AppColors.paperSoft)
            Circle()
                .fill(AppColors.green.opacity(0.12))
                .scaleEffect(breathe ? 1.04 : 0.80)
            Circle()
                .fill(AppColors.green.opacity(0.10))
                .scaleEffect(breathe ? 0.82 : 1.02)
            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(AppColors.green.opacity(0.60))
                .opacity(breathe ? 1.0 : 0.7)
        }
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: breathe)
        .onAppear { breathe = true }
    }
}

private struct ScenePortraitLoopingVideoView: UIViewRepresentable {
    let url: URL
    @EnvironmentObject var pip: CompanionWindowPiPController
    @Environment(\.scenePhase) private var scenePhase

    func makeUIView(context: Context) -> ScenePortraitPlayerView {
        let view = ScenePortraitPlayerView()
        view.load(url: url, pip: pip)
        return view
    }

    func updateUIView(_ uiView: ScenePortraitPlayerView, context: Context) {
        uiView.load(url: url, pip: pip)
        uiView.updateScenePhase(active: scenePhase == .active)
    }

    // Deliberately no dismantleUIView stopping PiP here: this view is also
    // torn down by incidental SwiftUI churn (not just the one intentional
    // "content is really gone" case, ScenePortraitRevertButton.revert(),
    // which already calls pip.stop() itself before it changes
    // observationVideoUrl). Auto-stopping on every dismantle would kill an
    // active PiP session over a rebuild unrelated to the user's intent.
}

private final class ScenePortraitPlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var loadedURL: URL?
    private var isScenePhaseActive = true

    // weak: this view doesn't own the controller's lifetime, just reads
    // isActive in refreshPlaybackState() so PiP playback isn't paused when
    // this view's window goes nil (e.g. switching away from the Home tab).
    fileprivate(set) weak var pip: CompanionWindowPiPController?

    fileprivate var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    func load(url: URL, pip: CompanionWindowPiPController) {
        self.pip = pip
        guard loadedURL != url else { return }
        loadedURL = url
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer(playerItem: item)
        queue.isMuted = true
        looper = AVPlayerLooper(player: queue, templateItem: item)
        playerLayer.player = queue
        playerLayer.videoGravity = .resizeAspectFill
        player = queue
        pip.attach(playerLayer: playerLayer)
        refreshPlaybackState()
    }

    func updateScenePhase(active: Bool) {
        isScenePhaseActive = active
        refreshPlaybackState()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        refreshPlaybackState()
    }

    // "Should be playing" has exactly two legitimate causes: genuinely
    // visible inline (attached to a real window, app in foreground), or PiP
    // currently presenting this same layer in its own floating window.
    // Consolidating both checks here (rather than scattering `window == nil`
    // checks across callbacks) is what lets the same player safely back
    // both playback contexts without a second, separately-maintained player.
    private func refreshPlaybackState() {
        let shouldPlay = (window != nil && isScenePhaseActive) || (pip?.isActive ?? false)
        shouldPlay ? player?.play() : player?.pause()
    }
}
