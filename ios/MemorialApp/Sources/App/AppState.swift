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
    // True while checkAuthAndLoad() is running — prevents RootView from flashing
    // OnboardingStartView before the async token check completes.
    // Initialised to true only when a Keychain token exists (user is probably logged in).
    @Published var isAuthChecking: Bool = KeychainHelper.loadToken() != nil
    @Published var hasSkippedOnboarding: Bool = false  // in-memory only; resets on every app launch
    @Published var selectedTab: Int = 0
    @Published var currentUser: User?
    @Published var currentPet: Pet?
    @Published var entitlement: Entitlement?
    @Published var photos: [Photo] = []
    @Published var story: Story?
    @Published var letters: [Letter] = []
    @Published var hugs: [Hug] = []
    @Published var share: Share?
    @Published var newHugCount: Int = 0
    @Published var tabBarHidden: Bool = false

    static let seenHugCountKey = "seen_hug_count"

    var isLoggedIn: Bool { currentUser != nil }
    var hasPet: Bool { currentPet != nil }
    var isPaid: Bool { entitlement?.isPaid == true }
    var photoCount: Int { photos.filter { $0.type == .album }.count }
    var photoLimit: Int { entitlement?.photoLimit ?? 9 }
    var canUploadPhoto: Bool { photoCount < photoLimit }
    var mailboxEnabled: Bool { entitlement?.mailboxEnabled == true }

    // MARK: - Launch Auth Check

    func checkAuthAndLoad() async {
        defer { isAuthChecking = false }
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
                // isPaid is derived from the albumPhotoLimit field returned by the backend.
                let isPaid = (first.albumPhotoLimit ?? 9) >= 50
                await loadSideData(token: token, petId: first.id, isPaid: isPaid)
            } else {
                ownerStage = .loggedInNoPet
            }
        } catch {
            print("loadCurrentPet error: \(error)")
            ownerStage = .loggedInNoPet
        }
    }

    private func loadSideData(token: String, petId: String, isPaid: Bool) async {
        if isPaid, let apiLetters = try? await APIClient.shared.fetchLetters(token: token, petId: petId) {
            letters = apiLetters.map { l in
                Letter(id: l.id, petId: l.petId, userId: currentUser?.id ?? "",
                       title: l.title, content: l.content,
                       createdAt: l.createdAt, updatedAt: l.updatedAt)
            }
        }
        if let apiHugs = try? await APIClient.shared.fetchHugs(token: token, petId: petId) {
            hugs = apiHugs.map { h in
                Hug(id: h.id, petId: petId, shareId: h.shareId,
                    visitorName: h.visitorName, source: "share", createdAt: h.createdAt)
            }
            let lastSeen = UserDefaults.standard.integer(forKey: AppState.seenHugCountKey)
            newHugCount = max(0, apiHugs.count - lastSeen)
        }
    }

    func createPet(name: String, type: Pet.PetType) async throws -> String {
        guard let token = KeychainHelper.loadToken() else { throw APIError.noToken }
        let pet = try await APIClient.shared.createPet(token: token, name: name, type: type)
        return pet.id
    }

    func uploadMainPhoto(petId: String, imageData: Data) async throws {
        guard let token = KeychainHelper.loadToken() else { throw APIError.noToken }
        let photo = try await APIClient.shared.uploadPhoto(token: token, petId: petId, imageData: imageData, type: "MAIN")
        try await APIClient.shared.updatePet(token: token, petId: petId, body: ["mainPhotoId": photo.id])
    }

    // MARK: - API → Domain Conversion

    private func applyPet(_ api: ApiPet) {
        // Photo type: use the `type` field returned by the backend (P0 model).
        // Fall back to mainPhotoId comparison for responses that don't include type.
        let domainPhotos: [Photo] = (api.photos ?? []).map { p in
            let isMain = (p.type == "MAIN") || (p.id == api.mainPhotoId)
            return Photo(
                id: p.id, petId: p.petId, userId: api.userId,
                type: isMain ? .main : .album,
                url: p.r2Url, thumbnailURL: p.r2Url,
                uploadStatus: .success, isMain: isMain,
                sortOrder: p.sortOrder, createdAt: p.createdAt
            )
        }
        photos = domainPhotos

        let mainDomainPhoto = domainPhotos.first(where: { $0.type == .main })

        currentPet = Pet(
            id: api.id,
            ownerUserId: api.userId,
            name: api.name,
            type: api.type.toDomain,
            mainPhotoId: api.mainPhotoId,
            mainPhoto: mainDomainPhoto,
            memorialSentence: api.memorialSentence,
            metOrAdoptionDate: api.arrivedOn.map { PartialDate(precision: .day, value: $0) },
            birthDate: api.bornOn.map { PartialDate(precision: .day, value: $0) },
            passedAwayDate: api.leftOn.map { PartialDate(precision: .day, value: $0) },
            status: .active,
            createdAt: api.createdAt
        )

        // Entitlement is user-level (P0). Backend returns albumPhotoLimit and
        // mailboxEnabled directly on the pet response; derive isPaid from limit.
        let limit = api.albumPhotoLimit ?? 9
        let mbEnabled = api.mailboxEnabled ?? false
        let isPaid = limit >= 50 || mbEnabled
        entitlement = Entitlement(
            entitlementType: isPaid ? .paid : .free,
            photoLimit: limit,
            mailboxEnabled: mbEnabled,
            purchaseStatus: isPaid ? .paid : .none
        )
        ownerStage = isPaid ? .hasPetPaid : .hasPetFree

        if let storyContent = api.story, !storyContent.isEmpty {
            story = Story(id: "story_\(api.id)", petId: api.id, content: storyContent,
                          visibility: .publicLink, createdAt: api.createdAt, updatedAt: api.createdAt)
        } else {
            story = nil
        }

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
    }

    // MARK: - Hugs

    func markHugsSeen() {
        UserDefaults.standard.set(hugs.count, forKey: AppState.seenHugCountKey)
        newHugCount = 0
    }

    // MARK: - Debug

    #if DEBUG
    func resetAll() {
        KeychainHelper.deleteToken()
        UserDefaults.standard.removeObject(forKey: AppState.seenHugCountKey)
        currentUser = nil
        currentPet = nil
        entitlement = nil
        photos = []
        story = nil
        letters = []
        hugs = []
        share = nil
        newHugCount = 0
        ownerStage = .unauthenticated
        isAuthChecking = false
        hasSkippedOnboarding = false
        selectedTab = 0
    }

    func debugLoginAndStart() async {
        do {
            let response = try await APIClient.shared.debugLogin()
            KeychainHelper.saveToken(response.accessToken)
            KeychainHelper.saveUserId(response.user.id)
            currentUser = User(id: response.user.id, loginStatus: .loggedIn,
                               loginProvider: "debug", nickname: nil, avatarURL: nil,
                               createdAt: response.user.createdAt)
            // Backend deletes all pets on debug login — clear local pet state so
            // stale currentPet/entitlement don't let the user reach mailbox with a
            // deleted petId and get a silent save failure.
            currentPet = nil
            entitlement = nil
            photos = []
            story = nil
            letters = []
            hugs = []
            share = nil
            newHugCount = 0
            UserDefaults.standard.removeObject(forKey: AppState.seenHugCountKey)
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
