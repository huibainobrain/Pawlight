import SwiftUI
import AVFoundation
import UIKit

// MARK: - Promo demo scaffold
//
// One-off scaffold used ONLY to record the Pawlight promo video. It fakes the
// "describe a scene -> pick a generated portrait -> observation window becomes a
// video" flow with bundled placeholder media and two fixed countdowns — no API,
// no StoreKit, no backend. Nothing here runs unless the DEBUG-only launch-screen
// button arms it (`PromoDemoController.isArmed` stays false in Release), so the
// heavy views below are compiled but unreachable in a shipping build.
//
// Remove `PromoDemo.swift`, the `Assets.xcassets/PromoDemo` group, and the
// `#if DEBUG` hooks in AppState / OnboardingStartView / MainPhotoView /
// TierSelectView / CreateSuccessView / HomeView before App Store submission.

enum PromoDemoConfig {
    // Spec'd waits. Drop both to ~4 for a quick end-to-end test, restore before recording.
    static let imageCountdown: TimeInterval = 45
    static let videoCountdown: TimeInterval = 85
    static let candidateCount = 4

    static let uploadedPhotoAsset = "promo_uploaded_photo"
    static func candidateAsset(_ index: Int) -> String { "promo_candidate_\(index + 1)" }
    static let videoAsset = "promo_observation_video"
}

// MARK: - Controller

@MainActor
final class PromoDemoController: ObservableObject {

    enum Stage: String {
        case inactive
        case awaitingSceneInput
        case generatingImage
        case awaitingCandidatePick
        case generatingVideo
        case showingVideo

        var isGenerating: Bool { self == .generatingImage || self == .generatingVideo }
    }

    @Published private(set) var isArmed = false
    @Published private(set) var stage: Stage = .inactive
    @Published private(set) var sceneText = ""
    @Published private(set) var candidateIndex: Int?

    /// True once the flow is past registration — the app relaunched mid-take and
    /// needs its mock pet rebuilt so Home (and the observation window) can render.
    var needsPetRestore: Bool {
        switch stage {
        case .inactive, .awaitingSceneInput: return false
        default: return isArmed
        }
    }

    private var deadline: Date?
    private var ticker: Task<Void, Never>?

    private enum Key {
        static let armed = "promoDemo.armed"
        static let stage = "promoDemo.stage"
        static let deadline = "promoDemo.deadline"
        static let candidate = "promoDemo.candidate"
        static let scene = "promoDemo.scene"
        static let all = [armed, stage, deadline, candidate, scene]
    }

    init() { restore() }

    // MARK: intent

    /// Launch-screen button: turn the demo on and clear any earlier take.
    func arm() {
        ticker?.cancel(); ticker = nil
        isArmed = true
        stage = .inactive
        sceneText = ""
        candidateIndex = nil
        deadline = nil
        persist()
    }

    /// Home calls this once the (mock) paid pet with a photo is on screen.
    func beginSceneInputIfNeeded() {
        guard isArmed, stage == .inactive else { return }
        stage = .awaitingSceneInput
        persist()
    }

    func submitScene(_ text: String) {
        guard stage == .awaitingSceneInput else { return }
        sceneText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        enterGenerating(.generatingImage, seconds: PromoDemoConfig.imageCountdown)
    }

    func pickCandidate(_ index: Int) {
        guard stage == .awaitingCandidatePick else { return }
        candidateIndex = index
        enterGenerating(.generatingVideo, seconds: PromoDemoConfig.videoCountdown)
    }

    /// Debug reset — back to a clean launch screen for the next take.
    func reset() {
        ticker?.cancel(); ticker = nil
        isArmed = false
        stage = .inactive
        sceneText = ""
        candidateIndex = nil
        deadline = nil
        Key.all.forEach { UserDefaults.standard.removeObject(forKey: $0) }
    }

    // MARK: timing

    private func enterGenerating(_ next: Stage, seconds: TimeInterval) {
        stage = next
        deadline = Date().addingTimeInterval(seconds)
        persist()
        startTicker()
    }

    private func startTicker() {
        ticker?.cancel()
        ticker = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(250))
                guard let self, self.deadline != nil else { return }
                self.tick()
            }
        }
    }

    private func tick() {
        guard let deadline, Date() >= deadline else { return }
        self.deadline = nil
        ticker?.cancel(); ticker = nil
        switch stage {
        case .generatingImage: stage = .awaitingCandidatePick
        case .generatingVideo: stage = .showingVideo
        default: break
        }
        persist()
    }

    // MARK: persistence (survives navigation, backgrounding, and cold launch mid-take)

    private func persist() {
        let d = UserDefaults.standard
        d.set(isArmed, forKey: Key.armed)
        d.set(stage.rawValue, forKey: Key.stage)
        d.set(sceneText, forKey: Key.scene)
        if let deadline { d.set(deadline.timeIntervalSince1970, forKey: Key.deadline) }
        else { d.removeObject(forKey: Key.deadline) }
        if let candidateIndex { d.set(candidateIndex, forKey: Key.candidate) }
        else { d.removeObject(forKey: Key.candidate) }
    }

    private func restore() {
        let d = UserDefaults.standard
        isArmed = d.bool(forKey: Key.armed)
        guard isArmed,
              let raw = d.string(forKey: Key.stage),
              let saved = Stage(rawValue: raw) else { return }
        stage = saved
        sceneText = d.string(forKey: Key.scene) ?? ""
        if d.object(forKey: Key.candidate) != nil {
            candidateIndex = d.integer(forKey: Key.candidate)
        }
        if d.object(forKey: Key.deadline) != nil {
            deadline = Date(timeIntervalSince1970: d.double(forKey: Key.deadline))
            tick()                       // elapsed while the app was closed? advance now
            if deadline != nil { startTicker() }
        }
    }
}

// MARK: - Home overlay (scene input + candidate picker)

extension View {
    /// Drives the two modal steps and the auto-trigger. Attach once, on Home.
    func promoDemoOverlay() -> some View { modifier(PromoDemoOverlay()) }
}

private struct PromoDemoOverlay: ViewModifier {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var promoDemo: PromoDemoController

    func body(content: Content) -> some View {
        content
            .onAppear(perform: trigger)
            .onChange(of: appState.hasPet) { _, _ in trigger() }
            .overlay {
                if promoDemo.isArmed {
                    Group {
                        switch promoDemo.stage {
                        case .awaitingSceneInput:
                            PromoSceneInputView { promoDemo.submitScene($0) }
                        case .awaitingCandidatePick:
                            PromoCandidatePickerView { promoDemo.pickCandidate($0) }
                        default:
                            EmptyView()
                        }
                    }
                    .animation(.easeInOut(duration: 0.28), value: promoDemo.stage)
                }
            }
            .overlay(alignment: .top) { resetBar }
    }

    /// The app's own debug ↺ sits behind the modal steps — this keeps a reset within
    /// reach at every point of the take. DEBUG-only, like the rest of the scaffold.
    @ViewBuilder private var resetBar: some View {
        #if DEBUG
        if promoDemo.isArmed, promoDemo.stage != .inactive {
            Button {
                appState.resetAll()
            } label: {
                Text("↺ 重置宣传片演示")
                    .font(AppFonts.body(11, weight: .medium))
                    .foregroundColor(AppColors.muted)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial, in: Capsule())
            }
            .padding(.top, 6)
        }
        #endif
    }

    private func trigger() {
        guard appState.isPromoDemoArmed, appState.hasPet else { return }
        promoDemo.beginSceneInputIfNeeded()
    }
}

// MARK: - S1 scene input

private struct PromoSceneInputView: View {
    let onSubmit: (String) -> Void
    @State private var text = ""
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            Color.black.opacity(0.42).ignoresSafeArea()

            VStack(spacing: 18) {
                VStack(spacing: 8) {
                    Text("想看到 TA 在什么样的地方？")
                        .font(AppFonts.serif(20, weight: .medium))
                        .foregroundColor(AppColors.ink)
                        .multilineTextAlignment(.center)
                    Text("写下一个场景，我们把 TA 画进去")
                        .font(AppFonts.body(13))
                        .foregroundColor(AppColors.muted)
                        .multilineTextAlignment(.center)
                }

                TextField("比如：在洒满阳光的窗台上打盹", text: $text, axis: .vertical)
                    .font(AppFonts.body(15))
                    .foregroundColor(AppColors.ink)
                    .lineLimit(3, reservesSpace: true)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(AppColors.paperSoft)
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.line, lineWidth: 1))
                    .focused($focused)

                Button {
                    focused = false
                    onSubmit(text)
                } label: {
                    Text("生成画像")
                        .font(AppFonts.body(16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(AppColors.greenDeep.opacity(0.9))
                        .cornerRadius(13)
                }
            }
            .padding(22)
            .background(AppColors.paper)
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 8)
            .padding(.horizontal, 32)
        }
        .transition(.opacity)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { focused = true }
        }
    }
}

// MARK: - S3 candidate picker

private struct PromoCandidatePickerView: View {
    let onPick: (Int) -> Void

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            Color.black.opacity(0.42).ignoresSafeArea()

            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    Text("选一张最像 TA 的")
                        .font(AppFonts.serif(20, weight: .medium))
                        .foregroundColor(AppColors.ink)
                    Text("轻点一张，把它带进星球观察窗")
                        .font(AppFonts.body(13))
                        .foregroundColor(AppColors.muted)
                }

                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(0..<PromoDemoConfig.candidateCount, id: \.self) { index in
                        Button {
                            onPick(index)
                        } label: {
                            Image(PromoDemoConfig.candidateAsset(index))
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .frame(height: 150)
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(AppColors.line, lineWidth: 1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(20)
            .background(AppColors.paper)
            .cornerRadius(22)
            .shadow(color: .black.opacity(0.12), radius: 24, x: 0, y: 8)
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }
}

// MARK: - Observation-window center content

struct PromoObservationContent: View {
    let stage: PromoDemoController.Stage
    let candidateIndex: Int?

    var body: some View {
        switch stage {
        case .showingVideo:
            PromoObservationVideo(candidateIndex: candidateIndex)
        case .generatingImage, .generatingVideo, .awaitingCandidatePick:
            PromoObservationLoading()
        default:
            Image(PromoDemoConfig.uploadedPhotoAsset)
                .resizable()
                .scaledToFill()
        }
    }
}

private struct PromoObservationLoading: View {
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

private struct PromoObservationVideo: View {
    let candidateIndex: Int?

    var body: some View {
        if let url = PromoDemoAssets.videoURL {
            PromoLoopingVideo(url: url)
        } else {
            // No mp4 supplied yet — show the picked candidate as a static stand-in so
            // the flow still visibly "finishes" during pre-asset testing.
            Image(PromoDemoConfig.candidateAsset(candidateIndex ?? 0))
                .resizable()
                .scaledToFill()
        }
    }
}

// MARK: - Looping muted video

private struct PromoLoopingVideo: UIViewRepresentable {
    let url: URL

    func makeUIView(context: Context) -> PromoPlayerView {
        let view = PromoPlayerView()
        view.load(url: url)
        return view
    }

    func updateUIView(_ uiView: PromoPlayerView, context: Context) {}
}

private final class PromoPlayerView: UIView {
    override class var layerClass: AnyClass { AVPlayerLayer.self }

    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?

    private var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }

    func load(url: URL) {
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

// MARK: - Bundled media

enum PromoDemoAssets {
    /// Materialises the bundled data-set mp4 to a temp file AVPlayer can open.
    /// Returns nil until a real `promo_observation_video.mp4` is added.
    static let videoURL: URL? = {
        guard let asset = NSDataAsset(name: PromoDemoConfig.videoAsset), !asset.data.isEmpty else {
            return nil
        }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("promo_observation_video.mp4")
        do {
            if !FileManager.default.fileExists(atPath: url.path) {
                try asset.data.write(to: url, options: .atomic)
            }
            return url
        } catch {
            return nil
        }
    }()
}
