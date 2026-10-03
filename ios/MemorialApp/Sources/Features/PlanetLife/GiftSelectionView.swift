import StoreKit
import SwiftUI

// PRD §26-30, §38: "给 TA 留点什么" — a one-time paid gesture, not an item
// shop. Same gift can always be bought again once its current instance
// completes; at most one Pending instance at a time (PRD §8.1). Select a
// gift card, then confirm with the single bottom CTA — this is a 2-column
// grid rather than one button per card specifically so the layout still
// reads cleanly once there are several real gifts (PRD §27 reference shows
// 5: ball/blanket/flowers/toy/star), not just the one test gift.
struct GiftSelectionView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var ls: LanguageStore
    @EnvironmentObject var planetLife: PlanetLifeController
    @EnvironmentObject var purchaseManager: PurchaseManager
    @Environment(\.dismiss) var dismiss

    @State private var selectedAssetId: String?
    @State private var isPurchasing = false
    @State private var showError = false

    private var s: Strings { ls.strings }
    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text(s.planetLifeGiftsIntro)
                        .font(AppFonts.body(13))
                        .foregroundColor(AppColors.muted)

                    if let pending = planetLife.gifts?.pending, let asset = pending.giftAsset {
                        Text(s.planetLifeGiftPendingBanner(name(for: asset)))
                            .font(AppFonts.body(13))
                            .foregroundColor(AppColors.green.opacity(0.8))
                            .padding(14)
                            .background(AppColors.green.opacity(0.08))
                            .cornerRadius(12)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        ForEach(planetLife.gifts?.assets ?? []) { asset in
                            GiftCard(
                                asset: asset,
                                product: asset.iosProductId.flatMap { purchaseManager.giftProducts[$0] },
                                name: name(for: asset),
                                description: description(for: asset),
                                isSelected: selectedAssetId == asset.id,
                                disabled: isDisabled(asset),
                                alreadyGivenLabel: s.planetLifeGiftAlreadyGivenBtn
                            ) {
                                selectedAssetId = asset.id
                            }
                        }
                    }

                    Text(s.planetLifeGiftOnePendingDisclaimer)
                        .font(AppFonts.body(11))
                        .foregroundColor(AppColors.muted.opacity(0.7))
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
                .padding(20)
                .padding(.bottom, 90) // room for the fixed bottom CTA
            }
            .background(AppColors.paper.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) { bottomCta }
            .navigationTitle(s.planetLifeGiftsNavTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(s.close) { dismiss() }
                }
            }
            .task {
                guard let petId = appState.currentPet?.id, let token = KeychainHelper.loadToken() else { return }
                await planetLife.loadGifts(token: token, petId: petId)
                let productIds = (planetLife.gifts?.assets ?? []).compactMap(\.iosProductId)
                await purchaseManager.loadGiftProducts(productIds: productIds)
            }
            .alert(s.planetLifeGiftPurchaseFailedTitle, isPresented: $showError) {
                Button(s.ok) {}
            } message: {
                Text(s.planetLifeGiftPurchaseFailedBody)
            }
        }
    }

    private func isDisabled(_ asset: ApiGiftAsset) -> Bool {
        planetLife.gifts?.canPurchase != true || asset.alreadyGiven == true
    }

    @ViewBuilder
    private var bottomCta: some View {
        if let selected = (planetLife.gifts?.assets ?? []).first(where: { $0.id == selectedAssetId }) {
            let product = selected.iosProductId.flatMap { purchaseManager.giftProducts[$0] }
            Button {
                Task { await purchase(selected) }
            } label: {
                HStack(spacing: 8) {
                    if isPurchasing { ProgressView().tint(.white) }
                    Text(s.planetLifeGiftBuyBtn(name(for: selected), product?.displayPrice ?? s.planetLifeGiftLoadingPrice))
                        .font(AppFonts.body(14, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(AppColors.greenDeep)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isPurchasing || product == nil)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)
        }
    }

    private func name(for asset: ApiGiftAsset) -> String {
        ls.language == .zh ? asset.nameZh : asset.nameEn
    }

    private func description(for asset: ApiGiftAsset) -> String {
        ls.language == .zh ? asset.descriptionZh : asset.descriptionEn
    }

    private func purchase(_ asset: ApiGiftAsset) async {
        guard let productId = asset.iosProductId,
              let token = KeychainHelper.loadToken(),
              let petId = appState.currentPet?.id else { return }
        isPurchasing = true
        defer { isPurchasing = false }

        let result = await purchaseManager.purchaseGift(productId: productId)
        switch result {
        case .success(let jws):
            do {
                try await APIClient.shared.verifyPurchase(token: token, jwsToken: jws)
                await planetLife.loadGifts(token: token, petId: petId)
                dismiss()
            } catch {
                showError = true
            }
        case .failure:
            showError = true
        }
    }
}

private struct GiftCard: View {
    let asset: ApiGiftAsset
    let product: Product?
    let name: String
    let description: String
    let isSelected: Bool
    let disabled: Bool
    let alreadyGivenLabel: String
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack(alignment: .topTrailing) {
                    // Placeholder illustration slot — see
                    // asset.illustrationAssetName in the production asset
                    // checklist; no art is generated here.
                    PlanetLifeIllustrationSlot(
                        assetName: asset.illustrationAssetName,
                        systemImageFallback: "gift.fill",
                        size: 84
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 6)

                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppColors.greenDeep)
                            .background(Circle().fill(.white))
                    }
                }

                Text(name)
                    .font(AppFonts.body(14, weight: .medium))
                    .foregroundColor(AppColors.ink)

                if asset.alreadyGiven == true {
                    Text(alreadyGivenLabel)
                        .font(AppFonts.body(11, weight: .medium))
                        .foregroundColor(AppColors.muted)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppColors.muted.opacity(0.12))
                        .cornerRadius(8)
                } else if let product {
                    Text(product.displayPrice)
                        .font(AppFonts.body(12, weight: .medium))
                        .foregroundColor(AppColors.green.opacity(0.8))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppColors.green.opacity(0.10))
                        .cornerRadius(8)
                }

                Text(description)
                    .font(AppFonts.body(11))
                    .foregroundColor(AppColors.muted)
                    .lineSpacing(1)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(AppColors.white)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppColors.green.opacity(0.6) : AppColors.line, lineWidth: isSelected ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(disabled)
        .opacity(disabled ? 0.55 : 1)
    }
}
