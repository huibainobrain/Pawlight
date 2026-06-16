import SwiftUI

enum OwnerStage {
    case unauthenticated
    case loggedInNoPet
    case hasPetFree
    case hasPetPaid
}

@MainActor
class AppState: ObservableObject {
    @Published var ownerStage: OwnerStage = .unauthenticated
    @Published var currentUser: User?
    @Published var currentPet: Pet?
    @Published var entitlement: Entitlement?
    @Published var photos: [Photo] = []
    @Published var story: Story?
    @Published var letters: [Letter] = []
    @Published var hugs: [Hug] = []
    @Published var share: Share?
    @Published var newHugCount: Int = 0

    // Derived state
    var isLoggedIn: Bool { currentUser != nil }
    var hasPet: Bool { currentPet != nil }
    var isPaid: Bool { entitlement?.isPaid == true }
    var photoCount: Int { photos.filter { $0.type == .album }.count }
    var photoLimit: Int { entitlement?.photoLimit ?? 9 }
    var canUploadPhoto: Bool { photoCount < photoLimit }
    var mailboxEnabled: Bool { entitlement?.mailboxEnabled == true }

    func loadMockData() {
        let mockUser = User(
            id: "usr_001",
            loginStatus: .loggedIn,
            loginProvider: "apple",
            nickname: nil,
            avatarURL: nil,
            createdAt: Date()
        )
        let mockPet = Pet(
            id: "pet_001",
            ownerUserId: "usr_001",
            name: "棉花",
            type: .cat,
            mainPhotoId: "photo_main_001",
            mainPhoto: nil,
            memorialSentence: "愿你在有风和阳光的地方，继续慢慢散步。",
            metOrAdoptionDate: PartialDate(precision: .year, value: "2016"),
            birthDate: PartialDate(precision: .unknown, value: nil),
            passedAwayDate: PartialDate(precision: .month, value: "2025-11"),
            status: .active,
            createdAt: Date()
        )
        let mockEntitlement = Entitlement(
            entitlementType: .free,
            photoLimit: 9,
            mailboxEnabled: false,
            purchaseStatus: .none
        )

        currentUser = mockUser
        currentPet = mockPet
        entitlement = mockEntitlement
        ownerStage = .hasPetFree
        newHugCount = 2
    }
}
