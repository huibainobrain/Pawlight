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
