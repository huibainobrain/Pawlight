import SwiftUI

struct TierSelectView: View {
    let petName: String
    let petType: Pet.PetType

    @EnvironmentObject var appState: AppState
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var ls: LanguageStore
    @Environment(\.dismiss) var dismiss
    @State private var navigateToSuccess = false
    @State private var selectedTier: Entitlement.EntitlementType?
    @State private var showPurchaseError = false
    @State private var purchaseErrorMessage = ""

    private var s: Strings { ls.strings }

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            VStack(spacing: 0) {

                StepIndicator(current: 2, total: 3)
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 16) {

                        // 标题 + 氛围元素
                        ZStack(alignment: .topLeading) {
                            HStack(spacing: 0) {
                                Spacer()
                                TierAmbientElement()
                                    .padding(.trailing, -36)
                            }
                            .allowsHitTesting(false)

                            VStack(alignment: .leading, spacing: 10) {
                                Text(s.tierStep)
                                    .font(AppFonts.body(12))
                                    .foregroundColor(AppColors.green)

                                Text(s.tierTitle(petName))
                                    .font(AppFonts.serif(26, weight: .medium))
                                    .foregroundColor(AppColors.ink)

                                Text(s.tierBody)
                                    .font(AppFonts.body(14))
                                    .foregroundColor(AppColors.muted)
                                    .lineSpacing(4)
                                    .padding(.trailing, 100)
                            }
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 4)

                        // 免费方案
                        TierCard(
                            title: s.tierFreeTitle,
                            subtitle: s.tierFreeSubtitle,
                            features: s.tierFreeFeatures,
                            price: nil,
                            badgeText: nil,
                            badgeStyle: .none,
                            titleIcon: "leaf.fill",
                            decoration: AnyView(FreePlanetDecoration()),
                            isSelected: selectedTier == .free,
                            isDisabled: false
                        ) { selectedTier = .free }

                        // 完整方案
                        TierCard(
                            title: s.tierPaidTitle,
                            subtitle: s.tierPaidSubtitle,
                            features: s.tierPaidFeatures,
                            price: TierPrice(current: "¥29.9", original: "¥59.9"),
                            badgeText: s.tierPaidBadge,
                            badgeStyle: .recommend,
                            titleIcon: "crown.fill",
                            decoration: AnyView(PaidDecoration()),
                            isSelected: selectedTier == .paid,
                            isDisabled: false
                        ) { selectedTier = .paid }

                        // 未来方案
                        TierCard(
                            title: s.tierFutureTitle,
                            subtitle: s.tierFutureSubtitle,
                            features: s.tierFutureFeatures,
                            price: nil,
                            badgeText: s.tierFutureBadge,
                            badgeStyle: .locked,
                            titleIcon: nil,
                            decoration: AnyView(FutureDecoration()),
                            isSelected: false,
                            isDisabled: true
                        ) {}
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                // 底部按钮
                Button {
                    confirmSelection()
                } label: {
                    ZStack {
                        if purchaseManager.state == .loading && selectedTier == .paid {
                            ProgressView().tint(AppColors.white)
                        } else {
                            Text(buttonTitle)
                                .font(AppFonts.body(16, weight: .medium))
                                .foregroundColor(selectedTier != nil ? AppColors.white : AppColors.muted)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(selectedTier != nil ? AppColors.greenDeep.opacity(0.86) : AppColors.line)
                    .cornerRadius(14)
                    .shadow(
                        color: selectedTier != nil ? AppColors.greenDeep.opacity(0.10) : .clear,
                        radius: 8, x: 0, y: 3
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)
                .padding(.bottom, 40)
                .disabled(selectedTier == nil || purchaseManager.state == .loading)
            }
        }
        .task { await purchaseManager.loadProduct() }
        .onChange(of: purchaseManager.state) { _, newState in
            switch newState {
            case .success:
                navigateToSuccess = true
            case .failed(let msg):
                purchaseErrorMessage = msg
                showPurchaseError = true
            default:
                break
            }
        }
        .alert(s.tierPurchaseErrorTitle, isPresented: $showPurchaseError) {
            Button(s.ok, role: .cancel) { purchaseManager.resetState() }
        } message: {
            Text(purchaseErrorMessage)
        }
        .navigationBarBackButtonHidden(true)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button { dismiss() } label: {
                    ZStack {
                        Circle()
                            .fill(AppColors.white)
                            .frame(width: 34, height: 34)
                            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
                        Image(systemName: "chevron.left")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColors.ink)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $navigateToSuccess) {
            CreateSuccessView()
        }
    }

    private var buttonTitle: String {
        switch selectedTier {
        case .free: return s.tierFreeBtnTitle
        case .paid:
            // No hardcoded currency fallback — while the region-priced Product is still
            // loading from StoreKit, show the plan name alone rather than guess a price.
            guard let price = purchaseManager.product?.displayPrice else { return s.tierPaidTitle }
            return s.tierPaidBtnTitle(price)
        default: return s.tierSelectPrompt
        }
    }

    private func confirmSelection() {
        guard let tier = selectedTier else { return }
        switch tier {
        case .free:
            navigateToSuccess = true
        case .paid:
            Task { await purchaseManager.purchase(appState: appState) }
        case .future:
            break
        }
    }
}

// MARK: - 顶部氛围元素

private struct TierAmbientElement: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.green.opacity(0.05))
                .frame(width: 124, height: 124)

            TierLeaf()
                .fill(AppColors.green.opacity(0.20))
                .frame(width: 24, height: 40)
                .rotationEffect(.degrees(-22))
                .offset(x: -10, y: -16)

            TierLeaf()
                .fill(AppColors.green.opacity(0.13))
                .frame(width: 18, height: 32)
                .rotationEffect(.degrees(34))
                .offset(x: 16, y: -4)

            TierLeaf()
                .fill(AppColors.green.opacity(0.09))
                .frame(width: 14, height: 24)
                .rotationEffect(.degrees(-54))
                .offset(x: 4, y: 24)

            Ellipse()
                .fill(AppColors.green.opacity(0.10))
                .frame(width: 48, height: 14)
                .offset(x: 0, y: 38)

            Image(systemName: "sparkle")
                .font(.system(size: 8, weight: .ultraLight))
                .foregroundColor(AppColors.greenDeep.opacity(0.25))
                .offset(x: -30, y: -22)

            Circle()
                .fill(AppColors.muted.opacity(0.09))
                .frame(width: 3, height: 3)
                .offset(x: 32, y: 16)
        }
        .frame(width: 124, height: 124)
    }
}

private struct TierLeaf: Shape {
    func path(in rect: CGRect) -> Path {
        Path { p in
            let w = rect.width, h = rect.height
            p.move(to: CGPoint(x: w * 0.5, y: 0))
            p.addCurve(to: CGPoint(x: w * 0.5, y: h),
                       control1: CGPoint(x: w, y: h * 0.25),
                       control2: CGPoint(x: w, y: h * 0.75))
            p.addCurve(to: CGPoint(x: w * 0.5, y: 0),
                       control1: CGPoint(x: 0, y: h * 0.75),
                       control2: CGPoint(x: 0, y: h * 0.25))
        }
    }
}

// MARK: - 方案卡片装饰插画

private struct FreePlanetDecoration: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(red: 0.55, green: 0.72, blue: 0.50).opacity(0.38),
                            Color(red: 0.36, green: 0.58, blue: 0.34).opacity(0.22),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 72, height: 72)

            GeometryReader { geo in
                let w = geo.size.width, h = geo.size.height
                Path { p in
                    p.move(to: CGPoint(x: 0, y: h * 0.64))
                    p.addCurve(
                        to: CGPoint(x: w, y: h * 0.68),
                        control1: CGPoint(x: w * 0.30, y: h * 0.44),
                        control2: CGPoint(x: w * 0.68, y: h * 0.78)
                    )
                    p.addLine(to: CGPoint(x: w, y: h))
                    p.addLine(to: CGPoint(x: 0, y: h))
                    p.closeSubpath()
                }
                .fill(Color(red: 0.32, green: 0.54, blue: 0.30).opacity(0.40))
            }
            .frame(width: 72, height: 72)
            .clipShape(Circle())

            Image(systemName: "sparkle")
                .font(.system(size: 8, weight: .ultraLight))
                .foregroundColor(.white.opacity(0.80))
                .offset(x: 4, y: -22)
        }
        .frame(width: 72, height: 72)
        .shadow(color: Color(red: 0.36, green: 0.58, blue: 0.34).opacity(0.14), radius: 8, x: 0, y: 3)
    }
}

private struct PaidDecoration: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(AppColors.gold.opacity(0.13))
                .frame(width: 72, height: 72)

            Circle()
                .fill(AppColors.gold.opacity(0.07))
                .frame(width: 52, height: 52)

            Image(systemName: "envelope.fill")
                .font(.system(size: 22))
                .foregroundColor(AppColors.gold.opacity(0.58))
                .offset(y: 2)

            Image(systemName: "heart.fill")
                .font(.system(size: 8))
                .foregroundColor(AppColors.rose.opacity(0.44))
                .offset(x: 10, y: -12)
        }
        .frame(width: 72, height: 72)
        .shadow(color: AppColors.gold.opacity(0.10), radius: 8, x: 0, y: 3)
    }
}

private struct FutureDecoration: View {
    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.muted.opacity(0.14), lineWidth: 1.5)
                .frame(width: 72, height: 72)

            Circle()
                .fill(AppColors.muted.opacity(0.06))
                .frame(width: 52, height: 52)

            Image(systemName: "lock.fill")
                .font(.system(size: 22))
                .foregroundColor(AppColors.muted.opacity(0.28))
        }
        .frame(width: 72, height: 72)
    }
}

// MARK: - Badge 样式

enum TierBadgeStyle {
    case none, recommend, locked
}

// MARK: - 方案卡片

struct TierPrice {
    let current: String
    let original: String
}

struct TierCard: View {
    let title: String
    let subtitle: String
    let features: [String]
    let price: TierPrice?
    let badgeText: String?
    let badgeStyle: TierBadgeStyle
    let titleIcon: String?
    let decoration: AnyView
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                // 推荐角标（在最顶层）
                if badgeStyle == .recommend, let badge = badgeText {
                    Text(badge)
                        .font(AppFonts.body(10, weight: .medium))
                        .foregroundColor(AppColors.white)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .background(AppColors.greenDeep.opacity(0.82))
                        .cornerRadius(8, corners: [.topRight, .bottomLeft])
                        .zIndex(1)
                }

                VStack(alignment: .leading, spacing: 0) {
                    // 标题区
                    HStack(alignment: .top, spacing: 0) {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(spacing: 6) {
                                if let icon = titleIcon {
                                    Image(systemName: icon)
                                        .font(.system(size: 12))
                                        .foregroundColor(
                                            isDisabled ? AppColors.muted.opacity(0.40) :
                                            (icon == "crown.fill" ? AppColors.gold : AppColors.green)
                                        )
                                }
                                Text(title)
                                    .font(AppFonts.body(16, weight: .medium))
                                    .foregroundColor(isDisabled ? AppColors.muted.opacity(0.55) : AppColors.ink)
                                if badgeStyle == .locked, let badge = badgeText {
                                    Text(badge)
                                        .font(AppFonts.body(10))
                                        .foregroundColor(AppColors.muted.opacity(0.60))
                                        .padding(.horizontal, 7)
                                        .padding(.vertical, 3)
                                        .background(AppColors.muted.opacity(0.09))
                                        .cornerRadius(5)
                                }
                            }
                            Text(subtitle)
                                .font(AppFonts.body(13))
                                .foregroundColor(isDisabled ? AppColors.muted.opacity(0.38) : AppColors.muted)
                        }

                        Spacer(minLength: 12)

                        // 价格（付费方案）or 插画（免费/未来方案）
                        if let price = price {
                            VStack(alignment: .trailing, spacing: 3) {
                                Text(price.current)
                                    .font(AppFonts.body(19, weight: .semibold))
                                    .foregroundColor(AppColors.greenDeep)
                                Text(price.original)
                                    .font(AppFonts.body(12))
                                    .foregroundColor(AppColors.muted.opacity(0.50))
                                    .strikethrough(color: AppColors.muted.opacity(0.38))
                            }
                            .padding(.top, 2)
                            .padding(.trailing, badgeStyle == .recommend ? 28 : 0)
                        } else {
                            decoration
                                .padding(.top, 2)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)

                    // 分隔线
                    Rectangle()
                        .fill(isDisabled ? AppColors.muted.opacity(0.06) : AppColors.line)
                        .frame(height: 1)
                        .padding(.horizontal, 18)
                        .padding(.top, 14)
                        .padding(.bottom, 14)

                    // 权益列表 + 付费方案插画并排
                    HStack(alignment: .bottom, spacing: 0) {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(features, id: \.self) { feature in
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(
                                            isDisabled ? AppColors.muted.opacity(0.28) :
                                            (isSelected ? AppColors.greenDeep : AppColors.green.opacity(0.78))
                                        )
                                        .frame(width: 14)
                                    Text(feature)
                                        .font(AppFonts.body(13))
                                        .foregroundColor(
                                            isDisabled ? AppColors.muted.opacity(0.38) : AppColors.ink.opacity(0.82)
                                        )
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)

                        // 付费方案：插画在权益列表右侧
                        if price != nil {
                            decoration
                                .padding(.leading, 8)
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, 18)
                }
                .background(
                    isSelected ? AppColors.green.opacity(0.055) :
                    (isDisabled ? AppColors.white.opacity(0.55) : AppColors.white)
                )
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isSelected ? AppColors.green.opacity(0.60) :
                            (isDisabled ? AppColors.muted.opacity(0.11) : AppColors.line),
                            lineWidth: isSelected ? 1.5 : 1
                        )
                )
                .shadow(
                    color: isDisabled ? .clear : Color.black.opacity(0.035),
                    radius: 8, x: 0, y: 2
                )
            }
        }
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.72 : 1)
    }
}

// MARK: - 圆角辅助

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        Path(UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        ).cgPath)
    }
}
