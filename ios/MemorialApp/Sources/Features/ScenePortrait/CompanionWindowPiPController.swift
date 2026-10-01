import AVFoundation
import AVKit
import UIKit

// Owns the AVPictureInPictureController for the observation-window video —
// the "随身观察窗" (companion window) feature. Deliberately holds no
// reference to AppState or ScenePortraitController: PiP is client playback
// state, scene-portrait generation is AI content state, and they must not
// be merged into one state machine. Bridging to AppState (e.g. navigating
// back to Home when the user returns from PiP) happens at the View layer,
// the same way PurchaseManager.purchase(appState:) bridges to AppState
// without storing it.
@MainActor
final class CompanionWindowPiPController: NSObject, ObservableObject {
    @Published private(set) var isActive: Bool = false {
        didSet {
            guard isActive, !oldValue else { return }
            UserDefaults.standard.set(true, forKey: Self.seenIntroKey)
        }
    }
    @Published private(set) var startFailure: Bool = false

    // Reactive, not a point-in-time snapshot: AVPictureInPictureController
    // only becomes "possible" once its content source's layer has a player
    // item ready to display, which can take a moment after attach(). Reading
    // isPictureInPicturePossible once at tap time caused false "not ready"
    // errors for a user who taps immediately after the screen appears.
    // isPictureInPicturePossible is KVO-compliant (@objc dynamic) specifically
    // so callers can observe it instead of guessing when to retry — this
    // mirrors Apple's own guidance for custom-player PiP buttons.
    @Published private(set) var isPossible: Bool = false

    static let seenIntroKey = "seen_companion_window_intro"
    var hasSeenIntro: Bool { UserDefaults.standard.bool(forKey: Self.seenIntroKey) }

    // Static device/OS capability, unlike isPossible — never changes during
    // a session, so it needs no observation. Lets the button distinguish
    // "will never work here" (e.g. this Simulator) from "working, just not
    // ready yet" instead of showing the same "try again" copy forever.
    var isSupported: Bool { AVPictureInPictureController.isPictureInPictureSupported() }

    // Set once by MainTabView (which already holds both this controller and
    // AppState via @EnvironmentObject): PiP's system "return to app" action
    // should land back on the Home tab, where the observation window lives.
    var onRestoreToForeground: (() -> Void)?

    private var pipController: AVPictureInPictureController?
    private weak var attachedLayer: AVPlayerLayer?
    private var isObservingPossible = false
    private static var possibleKVOContext = 0
    private static let possibleKeyPath = "isPictureInPicturePossible"

    func attach(playerLayer: AVPlayerLayer) {
        guard attachedLayer !== playerLayer else { return }
        stopObservingPossible()
        attachedLayer = playerLayer
        let source = AVPictureInPictureController.ContentSource(playerLayer: playerLayer)
        let controller = AVPictureInPictureController(contentSource: source)
        controller.canStartPictureInPictureAutomaticallyFromInline = false
        controller.delegate = self
        pipController = controller
        isPossible = controller.isPictureInPicturePossible
        // Swift's typed observe(\.keyPath) closure API hit a runtime trap
        // here ("null pointer... casting to NSObject") — AVPictureInPicture-
        // Controller's KVO notifications don't play safely with its
        // non-optional bridging. The classic string-keyPath API below takes
        // Any?/[NSKeyValueChangeKey: Any]? throughout, so the same bridging
        // situation is just an optional, not a trap.
        controller.addObserver(self, forKeyPath: Self.possibleKeyPath, options: [.new], context: &Self.possibleKVOContext)
        isObservingPossible = true
    }

    private func stopObservingPossible() {
        guard isObservingPossible else { return }
        pipController?.removeObserver(self, forKeyPath: Self.possibleKeyPath, context: &Self.possibleKVOContext)
        isObservingPossible = false
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey: Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard context == &Self.possibleKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        // AVFoundation isn't guaranteed to deliver this on the main thread;
        // isPossible is @Published and read by SwiftUI, so hop explicitly
        // rather than mutating it from whatever thread KVO calls back on.
        let newValue = (change?[.newKey] as? Bool) ?? false
        DispatchQueue.main.async { [weak self] in
            self?.isPossible = newValue
        }
    }

    func start() {
        guard let pipController, isPossible else { return }
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("[CompanionWindowPiP] audio session activate failed: \(error)")
        }
        pipController.startPictureInPicture()
    }

    func stop() {
        pipController?.stopPictureInPicture()
    }

    func acknowledgeStartFailure() {
        startFailure = false
    }
}

extension CompanionWindowPiPController: AVPictureInPictureControllerDelegate {
    func pictureInPictureControllerDidStartPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isActive = true
    }

    func pictureInPictureControllerDidStopPictureInPicture(_ pictureInPictureController: AVPictureInPictureController) {
        isActive = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        failedToStartPictureInPictureWithError error: Error
    ) {
        isActive = false
        startFailure = true
        // start() activates the audio session before calling
        // startPictureInPicture(); if the system rejects the start, didStop
        // never fires, so this is the only place left to release it —
        // otherwise a failed attempt would leave .playback occupying the
        // session indefinitely.
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        print("[CompanionWindowPiP] failed to start: \(error)")
    }

    func pictureInPictureController(
        _ pictureInPictureController: AVPictureInPictureController,
        restoreUserInterfaceForPictureInPictureStopWithCompletionHandler completionHandler: @escaping (Bool) -> Void
    ) {
        onRestoreToForeground?()
        completionHandler(true)
    }
}
