import SwiftUI

struct EntitlementView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var ls: LanguageStore

    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    private var s: Strings { ls.strings }

    // Mirrors TierSelectView's price-state handling: the buy button is the only
    // purchase entry point on this screen, so its failure text is "Purchase
    // unavailable" (the CTA-context string), not "Price unavailable" (which is
    // reserved for a card's own price display area).
    private var isPurchaseReady: Bool {
        purchaseManager.productLoadState == .loaded && purchaseManager.product?.displayPrice != nil
    }

    private var buyButtonTitle: String {
        switch purchaseManager.productLoadState {
        case .loading:
            return s.tierPaidPriceLoading
        case .failed:
            return s.tierPaidPurchaseUnavailable
        case .loaded:
            guard let price = purchaseManager.product?.displayPrice else {
                return s.tierPaidPurchaseUnavailable
            }
            return s.tierPaidBtnTitle(price)
        }
    }

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    if appState.isPaid {
                        PaidBadgeView()
                            .padding(.top, 24)
                    } else {
                        Text(s.entitlementSelectTitle)
                            .font(AppFonts.serif(22, weight: .medium))
                            .foregroundColor(AppColors.ink)
                            .padding(.top, 24)
                    }

                    EntitlementCompareView()
                        .padding(.horizontal, 20)

                    if !appState.isPaid {
                        Button {
                            Task { await purchaseManager.purchase(appState: appState) }
                        } label: {
                            ZStack {
                                if purchaseManager.state == .loading {
                                    ProgressView().tint(AppColors.white)
                                } else {
                                    Text(buyButtonTitle)
                                        .font(AppFonts.body(16, weight: .medium))
                                        .foregroundColor(isPurchaseReady ? AppColors.white : AppColors.muted)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(isPurchaseReady ? AppColors.greenDeep : AppColors.line)
                            .cornerRadius(12)
                        }
                        .disabled(!isPurchaseReady || purchaseManager.state == .loading)
                        .padding(.horizontal, 20)

                        Button {
                            Task { await purchaseManager.restorePurchases(appState: appState) }
                        } label: {
                            Text(s.entitlementRestoreBtn)
                                .font(AppFonts.body(13))
                                .foregroundColor(AppColors.muted)
                        }
                        .disabled(purchaseManager.state == .loading)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationTitle(s.entitlementNavTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        .task { await purchaseManager.loadProduct() }
        .onChange(of: purchaseManager.state) { _, newState in
            if case .failed(let msg) = newState {
                errorMessage = msg
                showErrorAlert = true
            }
        }
        .alert(s.entitlementErrorTitle, isPresented: $showErrorAlert) {
            Button(s.ok, role: .cancel) { purchaseManager.resetState() }
        } message: {
            Text(errorMessage)
        }
        .onDisappear {
            if purchaseManager.state != .success { purchaseManager.resetState() }
        }
    }
}

struct PaidBadgeView: View {
    @EnvironmentObject var ls: LanguageStore

    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(AppColors.gold.opacity(0.15)).frame(width: 80, height: 80)
                Image(systemName: "star.fill")
                    .font(.system(size: 32))
                    .foregroundColor(AppColors.gold)
            }
            Text(ls.strings.entitlementPaidTitle)
                .font(AppFonts.serif(20, weight: .medium))
                .foregroundColor(AppColors.ink)
        }
    }
}

struct EntitlementCompareView: View {
    @EnvironmentObject var ls: LanguageStore

    var body: some View {
        let s = ls.strings
        VStack(spacing: 0) {
            EntitlementRow(feature: s.entitlementFeatureMainPhoto, freeAvail: true, paidAvail: true)
            EntitlementRow(feature: s.entitlementFeatureStory, freeAvail: true, paidAvail: true)
            EntitlementRow(feature: s.entitlementFeaturePhotos, freeDetail: s.entitlementFeaturePhotosFree, paidDetail: s.entitlementFeaturePhotosPaid)
            EntitlementRow(feature: s.entitlementFeatureShare, freeAvail: true, paidAvail: true)
            EntitlementRow(feature: s.entitlementFeatureHugRecord, freeAvail: true, paidAvail: true)
            EntitlementRow(feature: s.entitlementFeatureMailbox, freeAvail: false, paidAvail: true)
        }
        .background(AppColors.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(AppColors.line, lineWidth: 1))
    }
}

struct EntitlementRow: View {
    let feature: String
    var freeAvail: Bool = false
    var paidAvail: Bool = false
    var freeDetail: String? = nil
    var paidDetail: String? = nil

    var body: some View {
        HStack {
            Text(feature)
                .font(AppFonts.body(14))
                .foregroundColor(AppColors.ink)
            Spacer()
            HStack(spacing: 24) {
                Group {
                    if let d = freeDetail {
                        Text(d).font(AppFonts.body(12)).foregroundColor(AppColors.muted)
                    } else {
                        Image(systemName: freeAvail ? "checkmark" : "minus")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(freeAvail ? AppColors.green : AppColors.muted)
                    }
                }
                .frame(width: 60, alignment: .center)

                Group {
                    if let d = paidDetail {
                        Text(d).font(AppFonts.body(12)).foregroundColor(AppColors.greenDeep)
                    } else {
                        Image(systemName: paidAvail ? "checkmark" : "minus")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(paidAvail ? AppColors.green : AppColors.muted)
                    }
                }
                .frame(width: 60, alignment: .center)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .overlay(Divider().padding(.horizontal, 16), alignment: .bottom)
    }
}
