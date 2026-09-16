import Foundation

// Real (non-demo) counterpart to PromoDemoController: drives "describe a scene
// -> pick a candidate -> observation window becomes a looping video" against
// the actual backend, polling GET /scene-portraits/:jobId instead of a local
// fake timer. Deliberately holds no reference to AppState — callers pass a
// completion closure so AppState refresh stays the caller's responsibility.
@MainActor
final class ScenePortraitController: ObservableObject {

    struct Candidate: Identifiable, Equatable {
        let id: String
        let url: String
    }

    enum Stage: Equatable {
        case idle
        case sceneInput
        case generatingImage
        case candidatePick(jobId: String, candidates: [Candidate])
        case generatingVideo
        case failed(message: String)

        var isActive: Bool {
            switch self {
            case .idle, .sceneInput: return false
            default: return true
            }
        }

        var isGenerating: Bool {
            switch self {
            case .generatingImage, .generatingVideo: return true
            default: return false
            }
        }
    }

    @Published private(set) var stage: Stage = .idle

    private static let pollInterval: Duration = .seconds(2)

    func beginSceneInput() {
        guard stage == .idle else { return }
        stage = .sceneInput
    }

    func cancelSceneInput() {
        guard stage == .sceneInput else { return }
        stage = .idle
    }

    func dismissError() {
        stage = .idle
    }

    func submitScene(
        token: String,
        petId: String,
        sceneText: String,
        onVideoReady: @escaping () -> Void
    ) async {
        guard stage == .sceneInput else { return }
        stage = .generatingImage
        do {
            let job = try await APIClient.shared.startScenePortrait(
                token: token, petId: petId, sceneText: sceneText
            )
            await poll(token: token, jobId: job.id, onVideoReady: onVideoReady)
        } catch {
            stage = .failed(message: Self.message(for: error))
        }
    }

    func pickCandidate(
        token: String,
        candidateId: String,
        onVideoReady: @escaping () -> Void
    ) async {
        guard case .candidatePick(let jobId, _) = stage else { return }
        stage = .generatingVideo
        do {
            _ = try await APIClient.shared.selectScenePortraitCandidate(
                token: token, jobId: jobId, candidateId: candidateId
            )
            await poll(token: token, jobId: jobId, onVideoReady: onVideoReady)
        } catch {
            stage = .failed(message: Self.message(for: error))
        }
    }

    // No persistence/resume-on-relaunch: unlike the promo demo, job state
    // lives server-side, so a completed job simply shows up on the next
    // normal pet fetch. A kill mid-poll just stops watching this attempt —
    // an accepted MVP gap (see the plan doc's manual follow-up notes).
    private func poll(token: String, jobId: String, onVideoReady: @escaping () -> Void) async {
        while !Task.isCancelled {
            do {
                let job = try await APIClient.shared.fetchScenePortraitJob(token: token, jobId: jobId)
                switch job.status {
                case .candidatesReady:
                    stage = .candidatePick(
                        jobId: job.id,
                        candidates: job.candidates
                            .sorted { $0.sortOrder < $1.sortOrder }
                            .map { Candidate(id: $0.id, url: $0.r2Url) }
                    )
                    return
                case .done:
                    stage = .idle
                    onVideoReady()
                    return
                case .failed:
                    stage = .failed(message: Self.message(forErrorCode: job.errorCode))
                    return
                case .queued, .generatingImage, .generatingVideo:
                    break
                }
            } catch {
                stage = .failed(message: Self.message(for: error))
                return
            }
            try? await Task.sleep(for: Self.pollInterval)
        }
    }

    private static func message(for error: Error) -> String {
        guard let apiError = error as? APIError, case .serverError(_, let body) = apiError else {
            return "生成遇到问题，请稍后再试"
        }
        if body.contains("PAID_ONLY") { return "这是完整纪念空间的功能" }
        if body.contains("NO_MAIN_PHOTO") { return "请先上传一张主照片" }
        if body.contains("SCENE_PORTRAIT_ATTEMPTS_EXHAUSTED") { return "生成次数已用完" }
        return "生成遇到问题，请稍后再试"
    }

    private static func message(forErrorCode code: String?) -> String {
        code == "PROVIDER_NOT_CONFIGURED"
            ? "画像功能暂未开放，请稍后再试"
            : "这次没有生成成功，可以再试一次"
    }
}
