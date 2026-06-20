import SwiftUI

private let h5BaseURL = "https://pet-memory-psi.vercel.app"

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

    var isLoggedIn: Bool { currentUser != nil }
    var hasPet: Bool { currentPet != nil }
    var isPaid: Bool { entitlement?.isPaid == true }
    var photoCount: Int { photos.filter { $0.type == .album }.count }
    var photoLimit: Int { entitlement?.photoLimit ?? 9 }
    var canUploadPhoto: Bool { photoCount < photoLimit }
    var mailboxEnabled: Bool { entitlement?.mailboxEnabled == true }

    // MARK: - Launch Auth Check

    func checkAuthAndLoad() async {
        guard let token = KeychainHelper.loadToken(),
              let userId = KeychainHelper.loadUserId() else {
            ownerStage = .unauthenticated
            return
        }
        currentUser = User(id: userId, loginStatus: .loggedIn, loginProvider: "apple",
                           nickname: nil, avatarURL: nil, createdAt: Date())
        await loadCurrentPet(token: token)
    }

    // MARK: - Login

    func login(identityToken: String) async throws {
        let response = try await APIClient.shared.login(identityToken: identityToken)
        KeychainHelper.saveToken(response.accessToken)
        KeychainHelper.saveUserId(response.user.id)
        currentUser = User(
            id: response.user.id,
            loginStatus: .loggedIn,
            loginProvider: "apple",
            nickname: response.user.nickname,
            avatarURL: response.user.avatarUrl,
            createdAt: response.user.createdAt
        )
        await loadCurrentPet(token: response.accessToken)
    }

    // MARK: - Pet

    func loadCurrentPet() async {
        guard let token = KeychainHelper.loadToken() else { return }
        await loadCurrentPet(token: token)
    }

    private func loadCurrentPet(token: String) async {
        do {
            let pets = try await APIClient.shared.fetchMyPets(token: token)
            if let first = pets.first {
                applyPet(first)
            } else {
                ownerStage = .loggedInNoPet
            }
        } catch {
            print("loadCurrentPet error: \(error)")
            ownerStage = .loggedInNoPet
        }
    }

    func createPet(name: String, type: Pet.PetType) async throws -> String {
        guard let token = KeychainHelper.loadToken() else { throw APIError.noToken }
        let pet = try await APIClient.shared.createPet(token: token, name: name, type: type)
        return pet.id
    }

    func uploadMainPhoto(petId: String, imageData: Data) async throws {
        guard let token = KeychainHelper.loadToken() else { throw APIError.noToken }
        let photo = try await APIClient.shared.uploadPhoto(token: token, petId: petId, imageData: imageData)
        try await APIClient.shared.updatePet(token: token, petId: petId, body: ["mainPhotoId": photo.id])
    }

    // MARK: - API → Domain Conversion

    private func applyPet(_ api: ApiPet) {
        currentPet = Pet(
            id: api.id,
            ownerUserId: api.userId,
            name: api.name,
            type: api.type.toDomain,
            mainPhotoId: api.mainPhotoId,
            mainPhoto: nil,
            memorialSentence: api.memorialSentence,
            metOrAdoptionDate: api.arrivedOn.map { PartialDate(precision: .day, value: $0) },
            birthDate: api.bornOn.map { PartialDate(precision: .day, value: $0) },
            passedAwayDate: api.leftOn.map { PartialDate(precision: .day, value: $0) },
            status: .active,
            createdAt: api.createdAt
        )

        let isPaid = api.entitlement?.tier == "PAID"
        entitlement = Entitlement(
            entitlementType: isPaid ? .paid : .free,
            photoLimit: isPaid ? 50 : 9,
            mailboxEnabled: isPaid,
            purchaseStatus: isPaid ? .paid : .none
        )
        ownerStage = isPaid ? .hasPetPaid : .hasPetFree

        if let s = api.share {
            share = Share(
                id: s.id,
                petId: s.petId,
                ownerUserId: api.userId,
                shareURL: "\(h5BaseURL)/s/\(s.slug)",
                visibility: s.visibility == "LINK" ? .link : .private,
                hugEnabled: s.hugEnabled,
                status: .active,
                createdAt: s.createdAt
            )
        }

        if let apiPhotos = api.photos {
            photos = apiPhotos.map { p in
                Photo(
                    id: p.id,
                    petId: p.petId,
                    userId: api.userId,
                    type: p.id == api.mainPhotoId ? .main : .album,
                    url: p.r2Url,
                    thumbnailURL: p.r2Url,
                    uploadStatus: .success,
                    isMain: p.id == api.mainPhotoId,
                    sortOrder: p.sortOrder,
                    createdAt: p.createdAt
                )
            }
        }
    }

    // MARK: - Debug

    #if DEBUG
    func debugLoginAndStart() async {
        do {
            let response = try await APIClient.shared.debugLogin()
            KeychainHelper.saveToken(response.accessToken)
            KeychainHelper.saveUserId(response.user.id)
            currentUser = User(id: response.user.id, loginStatus: .loggedIn,
                               loginProvider: "debug", nickname: nil, avatarURL: nil,
                               createdAt: response.user.createdAt)
            ownerStage = .loggedInNoPet
        } catch {
            print("debugLogin error: \(error)")
        }
    }
    #endif

    func loadMockData() {
        currentUser = User(id: "usr_001", loginStatus: .loggedIn, loginProvider: "apple",
                           nickname: nil, avatarURL: nil, createdAt: Date())
        currentPet = Pet(
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
        entitlement = Entitlement(entitlementType: .free, photoLimit: 9, mailboxEnabled: false, purchaseStatus: .none)
        ownerStage = .hasPetFree
        newHugCount = 2
    }
}
