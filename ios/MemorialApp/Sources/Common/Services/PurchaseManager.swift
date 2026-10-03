import StoreKit
import SwiftUI

@MainActor
final class PurchaseManager: ObservableObject {

    static let productId = "com.pawlight.full_memorial_space"

    @Published var product: Product?
    @Published var productLoadState: ProductLoadState = .loading
    @Published var state: PurchaseState = .idle

    enum ProductLoadState: Equatable {
        case loading
        case loaded
        case failed
    }

    // Bilingual text lives in Strings.swift (purchaseErrorMessage(_:)) — PurchaseManager
    // stays UI/localization-agnostic and just reports what happened.
    enum PurchaseError: Equatable, Error {
        case productLoadFailed
        case notSignedIn
        case verificationFailed
        case purchaseFailed
        case noValidPurchase
    }

    enum PurchaseState: Equatable {
        case idle
        case loading
        case success
        case failed(PurchaseError)
    }

    func loadProduct() async {
        guard product == nil else { return }
        productLoadState = .loading
        do {
            let products = try await Product.products(for: [Self.productId])
            if let first = products.first {
                product = first
                productLoadState = .loaded
            } else {
                productLoadState = .failed
            }
        } catch {
            print("[PurchaseManager] loadProduct: \(error)")
            productLoadState = .failed
        }
    }

    func purchase(appState: AppState) async {
        guard let product else {
            state = .failed(.productLoadFailed)
            return
        }
        guard let token = KeychainHelper.loadToken() else {
            state = .failed(.notSignedIn)
            return
        }
        state = .loading
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    state = .failed(.verificationFailed)
                    return
                }
                try await APIClient.shared.verifyPurchase(
                    token: token,
                    jwsToken: verification.jwsRepresentation
                )
                await transaction.finish()
                await appState.loadCurrentPet()
                state = .success

            case .userCancelled:
                state = .idle

            case .pending:
                // Waiting for parental approval (Ask to Buy).
                state = .idle

            @unknown default:
                state = .idle
            }
        } catch {
            state = .failed(.purchaseFailed)
        }
    }

    func restorePurchases(appState: AppState) async {
        guard let token = KeychainHelper.loadToken() else { return }
        state = .loading
        var found = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result,
                  transaction.productID == Self.productId,
                  transaction.revocationDate == nil else { continue }
            try? await APIClient.shared.verifyPurchase(
                token: token,
                jwsToken: result.jwsRepresentation
            )
            found = true
            break
        }
        if found {
            await appState.loadCurrentPet()
            state = .success
        } else {
            state = .failed(.noValidPurchase)
        }
    }

    func resetState() {
        state = .idle
    }

    // MARK: - Gift purchases (星球生活礼物)
    //
    // Deliberately parallel state, not reusing `product`/`state` above —
    // those two already drive EntitlementView/TierSelectView for the one
    // fixed full-memorial-space product, and a gift purchase can be any one
    // of several, repeatedly-purchasable product ids (PRD §8/§38).

    @Published var giftProducts: [String: Product] = [:] // keyed by StoreKit productId
    @Published var giftPurchaseState: PurchaseState = .idle

    func loadGiftProducts(productIds: [String]) async {
        guard !productIds.isEmpty else { return }
        do {
            let products = try await Product.products(for: productIds)
            for product in products {
                giftProducts[product.id] = product
            }
        } catch {
            print("[PurchaseManager] loadGiftProducts: \(error)")
        }
    }

    // Returns the verified JWS so the caller (PlanetLifeController) can
    // forward it to the gift-aware purchases/verify dispatch and learn the
    // resulting Gift Instance — PurchaseManager stays unaware of Planet Life
    // domain types, same separation as `purchase(appState:)` above.
    func purchaseGift(productId: String) async -> Result<String, PurchaseError> {
        guard let product = giftProducts[productId] else {
            giftPurchaseState = .failed(.productLoadFailed)
            return .failure(.productLoadFailed)
        }
        giftPurchaseState = .loading
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    giftPurchaseState = .failed(.verificationFailed)
                    return .failure(.verificationFailed)
                }
                let jws = verification.jwsRepresentation
                await transaction.finish()
                giftPurchaseState = .success
                return .success(jws)

            case .userCancelled:
                giftPurchaseState = .idle
                return .failure(.purchaseFailed)

            case .pending:
                giftPurchaseState = .idle
                return .failure(.purchaseFailed)

            @unknown default:
                giftPurchaseState = .idle
                return .failure(.purchaseFailed)
            }
        } catch {
            giftPurchaseState = .failed(.purchaseFailed)
            return .failure(.purchaseFailed)
        }
    }

    func resetGiftPurchaseState() {
        giftPurchaseState = .idle
    }
}
