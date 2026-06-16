import SwiftUI

struct TierSelectView: View {
    let petName: String
    let petType: Pet.PetType

    @EnvironmentObject var appState: AppState
    @State private var navigateToSuccess = false
    @State private var selectedTier: Entitlement.EntitlementType?
    @State private var isPurchasing = false

    var body: some View {
        ZStack {
            AppColors.paper.ignoresSafeArea()
            VStack(spacing: 0) {
                StepIndicator(current: 2, total: 3)
                    .padding(.top, 16)
                    .padding(.horizontal, 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("3 / 3  选择纪念空间")
                                .font(AppFonts.body(13))
                                .foregroundColor(AppColors.muted)
                            Text("为\(petName)选一个纪念空间")
                                .font(AppFonts.serif(24, weight: .medium))
                                .foregroundColor(AppColors.ink)
                        }
                        .padding(.top, 28)

                        TierCard(
                            title: "免费纪念空间",
                            subtitle: "先为TA留下一颗星球",
                            features: ["主照片", "首页星球观察窗", "TA的故事", "相册最多 9 张", "H5分享", "访客抱抱", "查看抱抱记录"],
                            price: nil,
                            isSelected: selectedTier == .free,
                            isDisabled: false
                        ) { selectedTier = .free }

                        TierCard(
                            title: "完整纪念空间",
                            subtitle: "更多照片，更完整的陪伴",
                            features: ["包含免费档全部内容", "相册最多 50 张照片", "天堂信箱（私密写信）", "更完整的保存感"],
                            price: TierPrice(current: "¥29.9", original: "¥59.9"),
                            isSelected: selectedTier == .paid,
                            isDisabled: false
                        ) { selectedTier = .paid }

                        TierCard(
                            title: "未来纪念形态",
                            subtitle: "更多纪念可能，即将开放",
                            features: ["视频回忆", "周年提醒", "更高级纪念视觉"],
                            price: nil,
                            isSelected: false,
                            isDisabled: true
                        ) {}
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }

                Button {
                    confirmSelection()
                } label: {
                    HStack(spacing: 8) {
                        if isPurchasing {
                            ProgressView().tint(AppColors.white)
                        }
                        Text(buttonTitle)
                            .font(AppFonts.body(16, weight: .medium))
                            .foregroundColor(selectedTier != nil ? AppColors.white : AppColors.muted)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(selectedTier != nil ? AppColors.greenDeep : AppColors.line)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
                .disabled(selectedTier == nil || isPurchasing)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $navigateToSuccess) {
            CreateSuccessView()
        }
    }

    private var buttonTitle: String {
        switch selectedTier {
        case .free: return "免费创建"
        case .paid: return "¥29.9 完整创建"
        default: return "请选择一个方案"
        }
    }

    private func confirmSelection() {
        guard let tier = selectedTier else { return }
        if tier == .paid {
            // TODO: StoreKit 2 purchase flow
            isPurchasing = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isPurchasing = false
                createPet(tier: tier)
            }
        } else {
            createPet(tier: tier)
        }
    }

    private func createPet(tier: Entitlement.EntitlementType) {
        // TODO: POST /api/v1/pets
        appState.currentPet = Pet(
            id: "pet_mock",
            ownerUserId: appState.currentUser?.id ?? "",
            name: petName,
            type: petType,
            mainPhotoId: nil,
            mainPhoto: nil,
            memorialSentence: nil,
            metOrAdoptionDate: nil,
            birthDate: nil,
            passedAwayDate: nil,
            status: .active,
            createdAt: Date()
        )
        appState.entitlement = Entitlement(
            entitlementType: tier,
            photoLimit: tier == .paid ? 50 : 9,
            mailboxEnabled: tier == .paid,
            purchaseStatus: tier == .paid ? .paid : .none
        )
        appState.ownerStage = tier == .paid ? .hasPetPaid : .hasPetFree
        navigateToSuccess = true
    }
}

struct TierPrice {
    let current: String
    let original: String
}

struct TierCard: View {
    let title: String
    let subtitle: String
    let features: [String]
    let price: TierPrice?
    let isSelected: Bool
    let isDisabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: 8) {
                            Text(title)
                                .font(AppFonts.body(16, weight: .medium))
                                .foregroundColor(isDisabled ? AppColors.muted : AppColors.ink)
                            if isDisabled {
                                Text("暂未开放")
                                    .font(AppFonts.body(11))
                                    .foregroundColor(AppColors.muted)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(AppColors.line)
                                    .cornerRadius(4)
                            }
                        }
                        Text(subtitle)
                            .font(AppFonts.body(13))
                            .foregroundColor(AppColors.muted)
                    }
                    Spacer()
                    if let price = price {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(price.current)
                                .font(AppFonts.body(18, weight: .semibold))
                                .foregroundColor(AppColors.greenDeep)
                            Text(price.original)
                                .font(AppFonts.body(12))
                                .foregroundColor(AppColors.muted)
                                .strikethrough()
                        }
                    }
                }
                Divider().background(AppColors.line)
                VStack(alignment: .leading, spacing: 6) {
                    ForEach(features, id: \.self) { feature in
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(isDisabled ? AppColors.muted : AppColors.green)
                            Text(feature)
                                .font(AppFonts.body(13))
                                .foregroundColor(isDisabled ? AppColors.muted : AppColors.ink)
                        }
                    }
                }
            }
            .padding(16)
            .background(isSelected ? AppColors.green.opacity(0.06) : AppColors.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? AppColors.green : AppColors.line,
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .opacity(isDisabled ? 0.55 : 1)
        }
        .disabled(isDisabled)
    }
}
