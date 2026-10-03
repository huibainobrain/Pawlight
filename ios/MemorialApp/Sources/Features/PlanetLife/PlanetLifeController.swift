import Foundation

// Drives Planet Life status/events/gifts against the real backend. Mirrors
// ScenePortraitController's shape: deliberately holds no reference to
// AppState — callers pass token/petId and read the published state back,
// same separation as the rest of this app's feature controllers.
@MainActor
final class PlanetLifeController: ObservableObject {

    @Published private(set) var status: ApiPlanetLifeStatus?
    @Published private(set) var events: [ApiPlanetEvent] = []
    @Published private(set) var gifts: ApiGiftsResponse?
    @Published private(set) var isLoading = false
    @Published var lastErrorCode: String?

    // PRD §12: choosing "稍后" on the home intro card must not keep re-
    // prompting — persisted locally (not server state), same idiom as
    // CompanionWindowPiPController.hasSeenIntro. Intentionally NOT cleared by
    // reset()/delete-account — a device-level "don't nag again" flag, same as
    // that controller's.
    static let introSeenKey = "seen_planet_life_intro"
    var hasSeenIntro: Bool { UserDefaults.standard.bool(forKey: Self.introSeenKey) }
    func markIntroSeen() { UserDefaults.standard.set(true, forKey: Self.introSeenKey) }

    // MARK: - Status / enable / settings

    func loadStatus(token: String, petId: String) async {
        do {
            status = try await APIClient.shared.fetchPlanetLifeStatus(token: token, petId: petId)
        } catch {
            lastErrorCode = Self.errorCode(from: error)
        }
    }

    @discardableResult
    func enable(token: String, petId: String, notifyOnNewEvent: Bool) async -> Bool {
        do {
            _ = try await APIClient.shared.enablePlanetLife(token: token, petId: petId, notifyOnNewEvent: notifyOnNewEvent)
            await loadStatus(token: token, petId: petId)
            return true
        } catch {
            lastErrorCode = Self.errorCode(from: error)
            return false
        }
    }

    @discardableResult
    func updateSettings(token: String, petId: String, notifyOnNewEvent: Bool? = nil, paused: Bool? = nil) async -> Bool {
        do {
            _ = try await APIClient.shared.updatePlanetLifeSettings(token: token, petId: petId, notifyOnNewEvent: notifyOnNewEvent, paused: paused)
            await loadStatus(token: token, petId: petId)
            return true
        } catch {
            lastErrorCode = Self.errorCode(from: error)
            return false
        }
    }

    // MARK: - Events (星球来信 / 星球纪事 — same object, different read state)

    func loadEvents(token: String, petId: String) async {
        isLoading = true
        defer { isLoading = false }
        do {
            events = try await APIClient.shared.fetchPlanetLifeEvents(token: token, petId: petId)
        } catch {
            lastErrorCode = Self.errorCode(from: error)
        }
    }

    // Restarts the wait server-side (PRD §19) — call once the user has
    // actually viewed the event's detail, not on every list render.
    @discardableResult
    func markRead(token: String, petId: String, eventId: String) async -> ApiPlanetEvent? {
        do {
            let updated = try await APIClient.shared.markPlanetEventRead(token: token, petId: petId, eventId: eventId)
            replaceLocalEvent(updated)
            if status?.unread?.id == eventId {
                await loadStatus(token: token, petId: petId)
            }
            return updated
        } catch {
            lastErrorCode = Self.errorCode(from: error)
            return nil
        }
    }

    // "不像 TA" (PRD §50) — hides the event and, if it carried a gift, voids
    // that fulfillment attempt so the Gift Instance returns to Pending.
    @discardableResult
    func markBadCase(token: String, petId: String, eventId: String) async -> Bool {
        do {
            let updated = try await APIClient.shared.markPlanetEventBadCase(token: token, petId: petId, eventId: eventId)
            replaceLocalEvent(updated)
            await loadGifts(token: token, petId: petId) // the reverted Pending gift affects canPurchase
            return true
        } catch {
            lastErrorCode = Self.errorCode(from: error)
            return false
        }
    }

    private func replaceLocalEvent(_ updated: ApiPlanetEvent) {
        if let idx = events.firstIndex(where: { $0.id == updated.id }) {
            events[idx] = updated
        }
    }

    // MARK: - Gifts

    func loadGifts(token: String, petId: String) async {
        do {
            gifts = try await APIClient.shared.fetchGifts(token: token, petId: petId)
        } catch {
            lastErrorCode = Self.errorCode(from: error)
        }
    }

    // MARK: - Local state reset
    //
    // Called from the View layer when AppState clears its local session
    // (delete-account or the DEBUG reset) — this controller has no reference
    // to AppState to react to that on its own (see the file header). Matches
    // the "View-layer-set closure" bridging idiom used for
    // CompanionWindowPiPController.onRestoreToForeground.
    func reset() {
        status = nil
        events = []
        gifts = nil
        isLoading = false
        lastErrorCode = nil
    }

    // MARK: - Error decoding
    //
    // Every structured error this feature's backend throws (PAID_ONLY,
    // NO_SCENE_PORTRAIT_YET, GIFT_ALREADY_PENDING, STAR_LIFE_NOT_ENABLED,
    // AI_PROVIDER_NOT_CONFIGURED) is a plain {code, message} JSON body — see
    // ApiPlanetLifeErrorBody. Falls back to nil for a non-HTTP or unparsable
    // error so callers show a generic message instead.
    static func errorCode(from error: Error) -> String? {
        guard case APIError.serverError(_, let body) = error,
              let data = body.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(ApiPlanetLifeErrorBody.self, from: data).code
    }

    #if DEBUG
    struct DebugError: Error {
        let code: String
        var missingProviders: [String] = []
    }

    @discardableResult
    func debugFakeTrigger(token: String, petId: String) async -> Result<ApiPlanetLifeStatus, DebugError> {
        do {
            let result = try await APIClient.shared.debugPlanetLifeFakeTrigger(token: token, petId: petId)
            status = result
            return .success(result)
        } catch {
            return .failure(DebugError(code: Self.errorCode(from: error) ?? "unknown_error"))
        }
    }

    @discardableResult
    func debugLiveTrigger(token: String, petId: String) async -> Result<Void, DebugError> {
        do {
            try await APIClient.shared.debugPlanetLifeLiveTrigger(token: token, petId: petId)
            return .success(())
        } catch {
            let missing = Self.missingProviders(from: error)
            let code = Self.errorCode(from: error) ?? "unknown_error"
            return .failure(DebugError(code: code, missingProviders: missing))
        }
    }

    private static func missingProviders(from error: Error) -> [String] {
        guard case APIError.serverError(_, let body) = error,
              let data = body.data(using: .utf8) else { return [] }
        return (try? JSONDecoder().decode(ApiPlanetLifeErrorBody.self, from: data).missing) ?? []
    }

    @discardableResult
    func debugSimulatePurchase(token: String, petId: String, giftAssetKey: String) async -> Result<ApiGiftInstance, DebugError> {
        do {
            let instance = try await APIClient.shared.debugSimulateGiftPurchase(token: token, petId: petId, giftAssetKey: giftAssetKey)
            await loadGifts(token: token, petId: petId)
            return .success(instance)
        } catch {
            return .failure(DebugError(code: Self.errorCode(from: error) ?? "unknown_error"))
        }
    }
    #endif
}
