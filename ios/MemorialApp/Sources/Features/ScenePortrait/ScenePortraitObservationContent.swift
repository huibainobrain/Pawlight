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

    func makeUIView(context: Context) -> ScenePortraitPlayerView {
        let view = ScenePortraitPlayerView()
        view.load(url: url)
        return view
    }

    func updateUIView(_ uiView: ScenePortraitPlayerView, context: Context) {
        uiView.load(url: url)
    }
}

private final class ScenePortraitPlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var loadedURL: URL?

    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    func load(url: URL) {
        guard loadedURL != url else { return }
        loadedURL = url
        let item = AVPlayerItem(url: url)
        let queue = AVQueuePlayer(playerItem: item)
        queue.isMuted = true
        looper = AVPlayerLooper(player: queue, templateItem: item)
        playerLayer.player = queue
        playerLayer.videoGravity = .resizeAspectFill
        player = queue
        queue.play()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        window == nil ? player?.pause() : player?.play()
    }
}
