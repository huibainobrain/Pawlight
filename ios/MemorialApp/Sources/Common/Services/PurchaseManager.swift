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
    enum PurchaseError: Equatable {
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
}
