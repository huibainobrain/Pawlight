import SwiftUI

struct EntitlementView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var ls: LanguageStore

    @State private var showErrorAlert = false
    @State private var errorMessage = ""

    private var s: Strings { ls.strings }

    // nil while the region-priced Product is still loading from StoreKit — deliberately
    // no hardcoded currency fallback, since a guessed number could show the wrong currency.
    private var priceLabel: String? {
        purchaseManager.product?.displayPrice
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
                                    VStack(spacing: 4) {
                                        Text(s.entitlementBuyBtn)
                                            .font(AppFonts.body(16, weight: .medium))
                                            .foregroundColor(AppColors.white)
                                        if let priceLabel {
                                            Text(priceLabel)
                                                .font(AppFonts.body(13, weight: .semibold))
                                                .foregroundColor(AppColors.white.opacity(0.85))
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(AppColors.greenDeep)
                            .cornerRadius(12)
                        }
                        .disabled(purchaseManager.state == .loading)
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
