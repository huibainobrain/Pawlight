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

    enum PurchaseState: Equatable {
        case idle
        case loading
        case success
        case failed(String)
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
            state = .failed("产品信息加载失败，请稍后再试。")
            return
        }
        guard let token = KeychainHelper.loadToken() else {
            state = .failed("请先登录。")
            return
        }
        state = .loading
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                guard case .verified(let transaction) = verification else {
                    state = .failed("购买验证未通过，请联系客服。")
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
            state = .failed("购买未能完成，请稍后重试。")
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
            state = .failed("未找到有效的购买记录。")
        }
    }

    func resetState() {
        state = .idle
    }
}
