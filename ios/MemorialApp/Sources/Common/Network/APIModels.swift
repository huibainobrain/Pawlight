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
    let entitlement: ApiEntitlement?
    let share: ApiShare?
    let photos: [ApiPhoto]?

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

    // Custom init because some endpoints omit relation fields (photos, entitlement, share)
    // Swift's synthesized Decodable throws keyNotFound for absent optional keys
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
        entitlement = try c.decodeIfPresent(ApiEntitlement.self, forKey: .entitlement)
        share = try c.decodeIfPresent(ApiShare.self, forKey: .share)
        photos = try c.decodeIfPresent([ApiPhoto].self, forKey: .photos)
    }

    enum CodingKeys: String, CodingKey {
        case id, userId, name, type, mainPhotoId, story, memorialSentence
        case arrivedOn, bornOn, leftOn, createdAt, entitlement, share, photos
    }
}

struct ApiEntitlement: Decodable {
    let id: String
    let petId: String
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
}

// MARK: - Letter

struct ApiLetter: Decodable {
    let id: String
    let petId: String
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
