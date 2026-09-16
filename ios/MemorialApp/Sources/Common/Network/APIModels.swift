import Foundation

// MARK: - Auth

struct AuthLoginResponse: Decodable {
    let accessToken: String
    let user: ApiUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case user
    }
}

struct ApiUser: Decodable {
    let id: String
    let appleUserId: String
    let email: String?
    let nickname: String?
    let avatarUrl: String?
    let createdAt: Date
}

// MARK: - Pet

struct ApiPet: Decodable {
    let id: String
    let userId: String
    let name: String
    let type: ApiPetType
    let mainPhotoId: String?
    let story: String?
    let memorialSentence: String?
    let arrivedOn: String?
    let bornOn: String?
    let leftOn: String?
    let createdAt: Date
    // Per-P0: entitlement is now user-level; the pet response no longer embeds it.
    // The backend returns these flattened quota/capability fields instead.
    let albumPhotoCount: Int?
    let albumPhotoLimit: Int?
    let mailboxEnabled: Bool?
    let share: ApiShare?
    let photos: [ApiPhoto]?
    // V2 scene portrait: null means "show the static main photo".
    let observationVideoUrl: String?

    enum ApiPetType: String, Decodable {
        case CAT, DOG, OTHER

        var toDomain: Pet.PetType {
            switch self {
            case .CAT: return .cat
            case .DOG: return .dog
            case .OTHER: return .other
            }
        }
    }

    // Custom init: some endpoints omit relation fields (photos, share).
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        userId = try c.decode(String.self, forKey: .userId)
        name = try c.decode(String.self, forKey: .name)
        type = try c.decode(ApiPetType.self, forKey: .type)
        mainPhotoId = try c.decodeIfPresent(String.self, forKey: .mainPhotoId)
        story = try c.decodeIfPresent(String.self, forKey: .story)
        memorialSentence = try c.decodeIfPresent(String.self, forKey: .memorialSentence)
        arrivedOn = try c.decodeIfPresent(String.self, forKey: .arrivedOn)
        bornOn = try c.decodeIfPresent(String.self, forKey: .bornOn)
        leftOn = try c.decodeIfPresent(String.self, forKey: .leftOn)
        createdAt = try c.decode(Date.self, forKey: .createdAt)
        albumPhotoCount = try c.decodeIfPresent(Int.self, forKey: .albumPhotoCount)
        albumPhotoLimit = try c.decodeIfPresent(Int.self, forKey: .albumPhotoLimit)
        mailboxEnabled = try c.decodeIfPresent(Bool.self, forKey: .mailboxEnabled)
        share = try c.decodeIfPresent(ApiShare.self, forKey: .share)
        photos = try c.decodeIfPresent([ApiPhoto].self, forKey: .photos)
        observationVideoUrl = try c.decodeIfPresent(String.self, forKey: .observationVideoUrl)
    }

    enum CodingKeys: String, CodingKey {
        case id, userId, name, type, mainPhotoId, story, memorialSentence
        case arrivedOn, bornOn, leftOn, createdAt
        case albumPhotoCount, albumPhotoLimit, mailboxEnabled
        case share, photos, observationVideoUrl
    }
}

// Entitlement is now user-level (P0 change). The pet response no longer
// embeds a per-pet entitlement; instead albumPhotoCount/albumPhotoLimit/
// mailboxEnabled are returned directly on the pet.
struct ApiEntitlement: Decodable {
    let id: String
    let userId: String
    let tier: String
    let createdAt: Date
}

struct ApiShare: Decodable {
    let id: String
    let petId: String
    let slug: String
    let visibility: String
    let hugEnabled: Bool
    let createdAt: Date
}

// MARK: - Photo

struct ApiPhoto: Decodable {
    let id: String
    let petId: String
    let r2Url: String
    let sortOrder: Int
    let createdAt: Date
    let type: String?  // "MAIN" | "ALBUM" — may be absent on older endpoints
}

// MARK: - Letter

struct ApiLetter: Decodable {
    let id: String
    let petId: String
    let title: String?
    let content: String
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Hug

struct ApiHug: Decodable {
    let id: String
    let shareId: String
    let visitorName: String?
    let message: String?
    let createdAt: Date
}

// MARK: - Scene Portrait (AI 场景画像/动态观察窗, 付费功能)

struct ApiScenePortraitCandidate: Decodable {
    let id: String
    let r2Url: String
    let sortOrder: Int
}

struct ApiScenePortraitJob: Decodable {
    enum Status: String, Decodable {
        case queued = "QUEUED"
        case generatingImage = "GENERATING_IMAGE"
        case candidatesReady = "CANDIDATES_READY"
        case generatingVideo = "GENERATING_VIDEO"
        case done = "DONE"
        case failed = "FAILED"
    }

    let id: String
    let petId: String
    let status: Status
    let sceneText: String
    let candidates: [ApiScenePortraitCandidate]
    let selectedCandidateId: String?
    let videoR2Url: String?
    let errorCode: String?
    let errorMessage: String?
    let createdAt: Date
    let updatedAt: Date
}
