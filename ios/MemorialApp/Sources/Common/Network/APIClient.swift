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
    func debugLogin() async throws -> AuthLoginResponse {
        let url = url("/api/v1/auth/debug-login")
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("musayang-debug-2024", forHTTPHeaderField: "X-Debug-Secret")
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

    // MARK: - Purchases

    func verifyPurchase(token: String, jwsToken: String) async throws {
        var req = URLRequest(url: url("/api/v1/purchases/verify"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.httpBody = try? JSONSerialization.data(withJSONObject: ["jws_token": jwsToken])
        try await performVoid(req)
    }

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
