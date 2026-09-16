import Foundation

// MARK: - User

struct User: Identifiable, Codable {
    let id: String
    var loginStatus: LoginStatus
    var loginProvider: String
    var nickname: String?
    var avatarURL: String?
    var createdAt: Date

    enum LoginStatus: String, Codable {
        case loggedOut = "logged_out"
        case loggedIn = "logged_in"
        case deleted
    }
}

// MARK: - Pet

struct Pet: Identifiable, Codable {
    let id: String
    var ownerUserId: String
    var name: String
    var type: PetType
    var mainPhotoId: String?
    var mainPhoto: Photo?
    var memorialSentence: String?
    // V2 scene portrait (paid-only): nil means the observation window shows
    // the static mainPhoto; non-nil is a looping video URL to play instead.
    var observationVideoUrl: String? = nil
    var metOrAdoptionDate: PartialDate?
    var birthDate: PartialDate?
    var passedAwayDate: PartialDate?
    var status: PetStatus
    var createdAt: Date

    enum PetType: String, Codable, CaseIterable {
        case cat, dog, other
        var displayName: String {
            switch self {
            case .cat: return "猫猫"
            case .dog: return "狗狗"
            case .other: return "其他小动物"
            }
        }
    }

    enum PetStatus: String, Codable {
        case active, hidden, deleted
    }
}

struct PartialDate: Codable {
    var precision: Precision
    var value: String?

    enum Precision: String, Codable {
        case unknown, year, month, day
    }

    var displayString: String {
        switch precision {
        case .unknown: return "未知"
        case .year: return value ?? "未知"
        case .month:
            guard let v = value else { return "未知" }
            return v.replacingOccurrences(of: "-", with: " 年 ") + " 月"
        case .day:
            guard let v = value,
                  let date = ISO8601DateFormatter().date(from: v + "T00:00:00Z") else { return value ?? "未知" }
            let fmt = DateFormatter()
            fmt.dateStyle = .medium
            fmt.locale = Locale(identifier: "zh_CN")
            return fmt.string(from: date)
        }
    }
}

// MARK: - Entitlement

struct Entitlement: Codable {
    var entitlementType: EntitlementType
    var photoLimit: Int
    var mailboxEnabled: Bool
    var purchaseStatus: PurchaseStatus

    enum EntitlementType: String, Codable {
        case free, paid, future
    }

    enum PurchaseStatus: String, Codable {
        case none, pending, paid, failed, cancelled, refunded
    }

    var isFree: Bool { entitlementType == .free }
    var isPaid: Bool { entitlementType == .paid }
}

// MARK: - Photo

struct Photo: Identifiable, Codable {
    let id: String
    var petId: String
    var userId: String
    var type: PhotoType
    var url: String
    var thumbnailURL: String
    var uploadStatus: UploadStatus
    var isMain: Bool
    var sortOrder: Int?
    var createdAt: Date

    enum PhotoType: String, Codable {
        case main, album
    }

    enum UploadStatus: String, Codable {
        case pending, success, failed, rejected
    }
}

// MARK: - Story

struct Story: Identifiable, Codable {
    let id: String
    var petId: String
    var content: String
    var visibility: Visibility
    var createdAt: Date
    var updatedAt: Date

    enum Visibility: String, Codable {
        case `private`, publicLink = "public_link"
    }
}

// MARK: - Letter

struct Letter: Identifiable, Codable {
    let id: String
    var petId: String
    var userId: String
    var title: String?
    var content: String
    var createdAt: Date
    var updatedAt: Date?
}

// MARK: - Hug

struct Hug: Identifiable, Codable {
    let id: String
    var petId: String
    var shareId: String
    var visitorName: String?
    var source: String
    var createdAt: Date
}

// MARK: - Share

struct Share: Identifiable, Codable {
    let id: String
    var petId: String
    var ownerUserId: String
    var shareURL: String
    var visibility: Visibility
    var hugEnabled: Bool
    var status: ShareStatus
    var createdAt: Date

    enum Visibility: String, Codable {
        case `private`, link
    }

    enum ShareStatus: String, Codable {
        case active, disabled, deleted
    }
}

// MARK: - Purchase

struct Purchase: Identifiable, Codable {
    let id: String
    var userId: String
    var productId: String
    var amount: Decimal
    var currency: String
    var status: PurchaseStatus
    var platformTransactionId: String?
    var createdAt: Date

    enum PurchaseStatus: String, Codable {
        case pending, success, failed, cancelled, refunded
    }
}
