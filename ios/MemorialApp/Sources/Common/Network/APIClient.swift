import Foundation
import UIKit

enum APIError: LocalizedError {
    case noToken
    case invalidResponse
    case serverError(Int, String)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .noToken: return "未登录"
        case .invalidResponse: return "服务器响应无效"
        case .serverError(let code, _): return "服务器错误 (\(code))"
        case .decodingError: return "数据解析失败"
        }
    }
}

final class APIClient {
    static let shared = APIClient()

    private let baseURL = "https://pet-memory-production.up.railway.app"

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let str = try container.decode(String.self)
            let fmt = ISO8601DateFormatter()
            fmt.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = fmt.date(from: str) { return date }
            fmt.formatOptions = [.withInternetDateTime]
            if let date = fmt.date(from: str) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Bad date: \(str)")
        }
        return d
    }()

    // MARK: - Auth

    func login(identityToken: String) async throws -> AuthLoginResponse {
        let url = url("/api/v1/auth/login")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["identity_token": identityToken])
        return try await perform(req)
    }

    #if DEBUG
    static let debugSecret = "pawlight-debug-2024"

    func debugLogin() async throws -> AuthLoginResponse {
        let url = url("/api/v1/auth/debug-login")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(Self.debugSecret, forHTTPHeaderField: "X-Debug-Secret")
        return try await perform(req)
    }
    #endif

    func deleteAccount(token: String) async throws {
        var req = URLRequest(url: url("/api/v1/auth/me"))
        req.httpMethod = "DELETE"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        try await performVoid(req)
    }

    // MARK: - Pets

    func fetchMyPets(token: String) async throws -> [ApiPet] {
        var req = URLRequest(url: url("/api/v1/pets/mine"))
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await perform(req)
    }

    func createPet(token: String, name: String, type: Pet.PetType) async throws -> ApiPet {
        var req = URLRequest(url: url("/api/v1/pets"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: [
            "name": name,
            "type": type.rawValue.uppercased(),
        ])
        return try await perform(req)
    }

    func updatePet(token: String, petId: String, body: [String: Any]) async throws {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)"))
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        let _: Empty = try await perform(req)
    }

    // MARK: - Photos

    func uploadPhoto(token: String, petId: String, imageData: Data, type: String = "ALBUM") async throws -> ApiPhoto {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/photos"))
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let boundary = "Boundary-\(UUID().uuidString)"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        var body = Data()
        // type field (MAIN or ALBUM)
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"type\"\r\n\r\n".data(using: .utf8)!)
        body.append(type.data(using: .utf8)!)
        body.append("\r\n".data(using: .utf8)!)
        // file field
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        return try await perform(req)
    }

    // MARK: - Letters

    func fetchLetters(token: String, petId: String) async throws -> [ApiLetter] {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/letters"))
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await perform(req)
    }

    func createLetter(token: String, petId: String, title: String?, content: String) async throws -> ApiLetter {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/letters"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        var body: [String: Any] = ["content": content]
        if let title { body["title"] = title }
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return try await perform(req)
    }

    func updateLetter(token: String, petId: String, letterId: String, title: String?, content: String) async throws -> ApiLetter {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/letters/\(letterId)"))
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        var body: [String: Any] = ["content": content]
        if let title { body["title"] = title }
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return try await perform(req)
    }

    func deleteLetter(token: String, petId: String, letterId: String) async throws {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/letters/\(letterId)"))
        req.httpMethod = "DELETE"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        try await performVoid(req)
    }

    // MARK: - Hugs

    func fetchHugs(token: String, petId: String) async throws -> [ApiHug] {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/hugs"))
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await perform(req)
    }

    func deletePhoto(token: String, petId: String, photoId: String) async throws {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/photos/\(photoId)"))
        req.httpMethod = "DELETE"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        try await performVoid(req)
    }

    // MARK: - Share

    func updateShare(token: String, petId: String, visibility: String, hugEnabled: Bool) async throws {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/share"))
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["visibility": visibility, "hugEnabled": hugEnabled])
        let _: Empty = try await perform(req)
    }

    // MARK: - Scene Portraits (AI 场景画像/动态观察窗, 付费功能)

    func startScenePortrait(token: String, petId: String, sceneText: String) async throws -> ApiScenePortraitJob {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/scene-portraits"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["sceneText": sceneText])
        return try await perform(req)
    }

    func fetchScenePortraitJob(token: String, jobId: String) async throws -> ApiScenePortraitJob {
        var req = URLRequest(url: url("/api/v1/scene-portraits/\(jobId)"))
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await perform(req)
    }

    func selectScenePortraitCandidate(token: String, jobId: String, candidateId: String) async throws -> ApiScenePortraitJob {
        var req = URLRequest(url: url("/api/v1/scene-portraits/\(jobId)/select"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["candidateId": candidateId])
        return try await perform(req)
    }

    func revertObservationWindow(token: String, petId: String) async throws {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/observation-window/revert"))
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        try await performVoid(req)
    }

    // MARK: - Purchases

    func verifyPurchase(token: String, jwsToken: String) async throws {
        var req = URLRequest(url: url("/api/v1/purchases/verify"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["jws_token": jwsToken])
        try await performVoid(req)
    }

    // MARK: - Planet Life (星球生活) + Gifts

    func fetchPlanetLifeStatus(token: String, petId: String) async throws -> ApiPlanetLifeStatus {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/planet-life"))
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await perform(req)
    }

    func enablePlanetLife(token: String, petId: String, notifyOnNewEvent: Bool) async throws -> ApiPlanetLifeState {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/planet-life/enable"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["notifyOnNewEvent": notifyOnNewEvent])
        return try await perform(req)
    }

    func updatePlanetLifeSettings(token: String, petId: String, notifyOnNewEvent: Bool?, paused: Bool?) async throws -> ApiPlanetLifeState {
        var body: [String: Any] = [:]
        if let notifyOnNewEvent { body["notifyOnNewEvent"] = notifyOnNewEvent }
        if let paused { body["paused"] = paused }
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/planet-life/settings"))
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: body)
        return try await perform(req)
    }

    func fetchPlanetLifeEvents(token: String, petId: String) async throws -> [ApiPlanetEvent] {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/planet-life/events"))
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await perform(req)
    }

    func markPlanetEventRead(token: String, petId: String, eventId: String) async throws -> ApiPlanetEvent {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/planet-life/events/\(eventId)/read"))
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await perform(req)
    }

    func markPlanetEventBadCase(token: String, petId: String, eventId: String) async throws -> ApiPlanetEvent {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/planet-life/events/\(eventId)/bad-case"))
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await perform(req)
    }

    func fetchGifts(token: String, petId: String) async throws -> ApiGiftsResponse {
        var req = URLRequest(url: url("/api/v1/pets/\(petId)/gifts"))
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return try await perform(req)
    }

    #if DEBUG
    func debugPlanetLifeFakeTrigger(token: String, petId: String) async throws -> ApiPlanetLifeStatus {
        var req = URLRequest(url: url("/api/v1/debug/pets/\(petId)/planet-life/fake-trigger"))
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(Self.debugSecret, forHTTPHeaderField: "X-Debug-Secret")
        return try await perform(req)
    }

    func debugPlanetLifeLiveTrigger(token: String, petId: String) async throws {
        var req = URLRequest(url: url("/api/v1/debug/pets/\(petId)/planet-life/live-trigger"))
        req.httpMethod = "POST"
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(Self.debugSecret, forHTTPHeaderField: "X-Debug-Secret")
        try await performVoid(req)
    }

    func debugSimulateGiftPurchase(token: String, petId: String, giftAssetKey: String) async throws -> ApiGiftInstance {
        var req = URLRequest(url: url("/api/v1/debug/pets/\(petId)/gifts/simulate-purchase"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue(Self.debugSecret, forHTTPHeaderField: "X-Debug-Secret")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["giftAssetKey": giftAssetKey])
        return try await perform(req)
    }
    #endif

    // MARK: - Private

    private struct Empty: Decodable {}

    private func performVoid(_ request: URLRequest) async throws {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
    }

    private func url(_ path: String) -> URL {
        URL(string: baseURL + path)!
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw APIError.invalidResponse }
        guard (200..<300).contains(http.statusCode) else {
            throw APIError.serverError(http.statusCode, String(data: data, encoding: .utf8) ?? "")
        }
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            print("Decode error for \(T.self): \(error)")
            print("Raw response: \(String(data: data, encoding: .utf8) ?? "")")
            throw APIError.decodingError(error)
        }
    }
}
